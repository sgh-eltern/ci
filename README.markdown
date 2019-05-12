# CI for SGH Elternbeirat

[![Build Status](https://travis-ci.org/sgh-eltern/ci.svg?branch=master)](https://travis-ci.org/sgh-eltern/ci)

# Deployment

* `git clone` this repository
* Copy `sample-config.yml` to `config.yml` and fill in the values (check Lastpass)
* Get a recent Ruby and install bundler in it
* Run `bundle exec rake deploy` to generate the scripts and config into the `deployment` folder and deploy them to the Strato box.

# Backup

Database and filesystem are both backed up from `~/bin/backup.sh`. It is generated and deployed from the [ci](https://github.com/sgh-eltern/ci#deployment) project. The invocation of `backup.sh` is scheduled as cron job via Strato's web interface.

## Rotation

Strategy:

1. If there is no backup for today yet, create it and put it into `backup/daily`
1. Delete files older than 7 days from `backup/daily`, so that we keep daily backups of the last seven days

1. If it is the last day of the week, copy the backup into `backup/weekly`, too
1. Delete files older than one month from `backup/weekly`, so that we keep weekly backups of the last month

1. If it is the last day of the month, copy the backup into `backup/monthly`, too
1. Delete files older than three months from `backup/monthly`, so that we keep monthly backups of the last three months

1. If it is the last day of the year, copy the backup into `backup/yearly`, too
1. Delete files older than 10 years from `backup/yearly`, so that we keep yearly backups of the last ten years

## Retention Management

### On the Strato Host (TODO)

In the pipeline, delete files older than `N` days like this:

```bash
find backup/*/monthly -name *.gz -type f -mtime +92
```

* `N` needs to be adjusted for yearly/monthly/weekly/daily
* Cleanup must only happen after files were successfully stowed at Backblaze

### At Backblaze (TODO)

The CI task for backblaze already has a candidate call.

## Development

Strato only has Ruby 1.9.3 available on their machines. Thus we need to run with it, but still want to develop and test with newer Rubies.

Here is how to update the runtime bundles:

```bash
$ chruby 1.9.3
$ bundle install --without=development --with=test
$ bundle exec rake
$ bundle update
```

Development and test can be done with a newer Ruby:

```bash
$ chruby 2.4.2
$ bundle install --with=development --with=test
$ bundle exec rake
$ bundle update
```

# Pipeline

* Base image is in `Dockerfile` and automatically built on [cloud.docker.com](https://cloud.docker.com/app/sghakinternet/repository/docker/sghakinternet/wiki)

* Backup user authenticates with private key:
  - Keys were generated with `ssh-keygen -t rsa -b 4096 -C "backup-pipeline@eltern-sgh.de" -f id_backup-pipeline`
  - Private key added as note to Lastpass entry 'SGH/ssh.strato.de'
  - Public key added to `~/.ssh/authorized_keys` in ssh.strato.de with `ssh-copy-id -i id_backup-pipeline.pub eltern-sgh.de@ssh.strato.de`

## Operating the Pipeline

1. Copy `sample-private-config.yml` to `private-config.yml` and fill in the values. Do not add this to the repo!
1. Call `set-pipeline` in order to apply the config.

# Test

## Schedule for Ghost

          | Eltern | Wiki | Freunde | GEB
----------|:------:|:----:|:-------:|:---:
Monday    |   x    |   x  |    x    |
Truesday  |   x    |   x  |    x    |  x
Wednesday |   x    |      |    x    |  x
Thursday  |   x    |   x  |         |  x
Friday    |   x    |   x  |    x    |
Saturday  |        |   x  |         |  x
Sunday    |   x    |      |    x    |  x
