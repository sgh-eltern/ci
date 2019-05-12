# frozen_string_literal: true

require_relative '../templates/bin/backup_repository'
require 'digest'
require 'pathname'
require 'tmpdir'
require 'timecop'
require 'securerandom'

describe SGH::BackupRepository do
  subject(:repository) { SGH::BackupRepository.new(repository_folder) }
  let(:now) { Time.now }
  let(:today) { now.to_date }
  let(:repository_folder) { Pathname(Dir.mktmpdir) }
  let(:daily_folder) { repository_folder.join('daily').tap(&:mkpath) }
  let(:todays_backup) { daily_folder.join("backup-#{now.strftime('%Y-%m-%d')}.txt") }

  before do
    Timecop.freeze(now)
  end

  after do
    FileUtils.remove_entry(repository_folder)
    Timecop.return
  end

  def digest(file_path)
    Digest::SHA256.new.hexdigest(Pathname(file_path).binread)
  end

  def fake_daily_backup(day)
    fake_backup(daily_folder.join("backup-#{day.strftime('%Y-%m-%d')}.txt"), day)
  end

  def fake_weekly_backup(day)
    fake_backup(weekly_folder.join("backup-#{day.strftime('%Y-%m-%d')}.txt"), day)
  end

  def fake_monthly_backup(day)
    fake_backup(monthly_folder.join("backup-#{day.strftime('%Y-%m-%d')}.txt"), day)
  end

  def fake_backup(file, day)
    File.write(file, SecureRandom.uuid)
    FileUtils.touch(file, mtime: Time.utc(day.year, day.month, day.day, 0, 15, 0))
  end

  context 'after a daily backup was performed' do
    let(:now) { Time.utc(2016, 8, 28, 0, 25, 0) }

    before do
      ((today - 10)..today).each do |date|
        fake_daily_backup(date)
      end
    end

    it 'deletes files older than 7 days from backup/daily' do
      expect(daily_folder.children.size).to be > 7

      repository.retain!

      # files older than seven days are gone
      expect(daily_folder.children.size).to eq(7)

      daily_backup_names = daily_folder.children.map(&:basename).map(&:to_s)
      expect(daily_backup_names).to contain_exactly(
        'backup-2016-08-22.txt',
        'backup-2016-08-23.txt',
        'backup-2016-08-24.txt',
        'backup-2016-08-25.txt',
        'backup-2016-08-26.txt',
        'backup-2016-08-27.txt',
        'backup-2016-08-28.txt',
      )
    end
  end

  context 'when it is the last day of the week' do
    let(:now) { Time.utc(2015, 7, 26, 0, 25, 0) }
    let(:weekly_folder) { repository_folder.join('weekly').tap(&:mkpath) }

    before do
      fake_daily_backup(today)

      ((today - 7 * 5)..(today - 7)).step(7).each do |date|
        fake_weekly_backup(date)
      end
    end

    it 'is a Sunday' do
      expect(now.sunday?).to be_truthy
    end

    it "copies today's backup into the weekly folder" do
      repository.retain!

      weekly_backups = weekly_folder.children.sort_by(&:mtime)
      expect(weekly_backups).to_not be_empty

      latest_weekly_backup = weekly_backups.last
      expect(latest_weekly_backup.basename).to eq(todays_backup.basename)
      expect(digest(latest_weekly_backup)).to eq(digest(todays_backup))
    end

    it 'deletes files older than four weeks from the weekly folder' do
      expect(weekly_folder.children.size).to be > 4
      repository.retain!
      expect(weekly_folder.children.size).to eq(4)

      weekly_backup_names = weekly_folder.children.map(&:basename).map(&:to_s)
      expect(weekly_backup_names).to contain_exactly(
        'backup-2015-07-05.txt',
        'backup-2015-07-12.txt',
        'backup-2015-07-19.txt',
        'backup-2015-07-26.txt',
      )
    end
  end

  context 'when it is the last day of the month' do
    let(:now) { Time.utc(2014, 6, 30, 0, 25, 0) }
    let(:monthly_folder) { repository_folder.join('monthly').tap(&:mkpath) }

    before do
      fake_daily_backup(today)

      fake_monthly_backup(Date.new(2014, 5, 31))
      fake_monthly_backup(Date.new(2014, 4, 30))
      fake_monthly_backup(Date.new(2014, 3, 31))
      fake_monthly_backup(Date.new(2014, 2, 28))
      fake_monthly_backup(Date.new(2014, 1, 31))
      fake_monthly_backup(Date.new(2013, 12, 31))
      fake_monthly_backup(Date.new(2013, 11, 30))
    end

    it 'is the last day of the month' do
      expect(today).to eq(Date.new(today.year, today.month, -1))
    end

    it "copies today's backup into the monthly folder" do
      repository.retain!

      monthly_backups = monthly_folder.children.sort_by(&:mtime)
      expect(monthly_backups).to_not be_empty

      latest_monthly_backup = monthly_backups.last
      expect(latest_monthly_backup.basename).to eq(todays_backup.basename)
      expect(digest(latest_monthly_backup)).to eq(digest(todays_backup))
    end

    it 'deletes files older than 6 months from the monthly folder' do
      expect(monthly_folder.children.size).to be > 6
      repository.retain!
      expect(monthly_folder.children.size).to eq(6)

      monthly_backup_names = monthly_folder.children.map(&:basename).map(&:to_s)
      expect(monthly_backup_names).to contain_exactly(
        'backup-2014-06-30.txt',
        'backup-2014-05-31.txt',
        'backup-2014-04-30.txt',
        'backup-2014-03-31.txt',
        'backup-2014-02-28.txt',
        'backup-2014-01-31.txt',
      )
    end
  end

  xcontext 'when it is the last day of the year' do
    it "copies today's backup into the yearly folder" do
    end

    it 'deletes files older than 10 years from the yearly folder' do
      # yearly backups of the last ten years are kept
    end
  end
end
