#!/usr/bin/env bash

# Generated from <%= template %>

create_folders() {
  local root=${1?Missing argument for root folder}
  mkdir -p "${root}"/{daily,weekly,monthly,yearly}
}

rotate_backups() {
  local root=${1?Missing argument for root folder}

  echo
  echo Rotating backup files...
  bin/rotate-backups "${root}"
  echo ...done.
}

list_backups() {
  local root=${1?Missing argument for root folder}

  echo
  echo "Contents of backup directory ${root}:"
  echo
  ls -ltr "${root}"/*
  echo
}

register_latest(){
  local registrant=${1?Missing argument for file to register}
  local registry=${2?Missing argument for registry folder}

  # At Strato, scp doesn't seem to follow symlinks, so we write the file path
  # to a file which can then be read to find out the latest backup
  echo "Registering ${registrant} as latest in ${registry}/latest"
  echo "${registrant}" > "${registry}"/latest
}

dump_files(){
  local src=${1?Missing argument for src folder}
  local root=${2?Missing argument for root folder}

  BACKUP_FILE="${root}"/daily/"${src}"_$(date "+%Y-%m-%d_%H%M").tar.gz

  echo
  echo "Creating daily backup for ${src} as ${BACKUP_FILE} ..."
  tar \
      --create \
      --exclude "${src}/wp-content/backupwordpress-*-backups/*" \
      --exclude-vcs \
      --gzip \
      --file \
    "${BACKUP_FILE}" "${src}"

  register_latest "${BACKUP_FILE}" "${root}"
  echo ...done.
}

dump_database(){
  local prefix="${1?Missing argument for the file prefix}"
  local db="${2?Missing argument for the database name}"
  local user="${3?Missing argument for the database user}"
  local password="${4?Missing argument for the database password}"
  local root="${5?Missing argument for root folder}"

  local latest_snapshot
  latest_snapshot="$(mysqlbackups "$db" | head -1)"
  local backup_file
  backup_file="${root}"/daily/"${prefix}"-db_$(date "+%Y-%m-%d_%H%M").sql.gz

  echo
  echo "Saving latest database snapshot ${latest_snapshot} to ${backup_file}:"
  mysqldump \
      --add-drop-table \
      --host="${latest_snapshot}" \
      --user="$user" \
      --password="$password" \
    "${db}" \
  | gzip \
  > "${backup_file}"

  register_latest "${backup_file}" "${root}"
  echo ...done.
}

backup_files() {
  local src=${1?Missing argument for src folder}
  local root=${2?Missing argument for root folder}

  create_folders "${root}"
  dump_files "${src}" "${root}"
  rotate_backups "${root}"
  list_backups "${root}"
}

backup_db(){
  local prefix="${1?Missing argument for the file prefix}"
  local db="${2?Missing argument for the database name}"
  local user="${3?Missing argument for the database user}"
  local password="${4?Missing argument for the database password}"
  local root="${5?Missing argument for root folder}"

  create_folders "${root}"
  dump_database \
    "$prefix" \
    "$db" \
    "$user" \
    "$password" \
    "${root}"
  rotate_backups "${root}"
  list_backups "${root}"
}

backup_files mediawiki backup/mediawiki-files
backup_db \
  mediawiki \
  "<%= config['mediawiki']['source_db'] %>" \
  "<%= config['mediawiki']['source_user'] %>" \
  "<%= config['mediawiki']['source_password'] %>" \
  backup/mediawiki-db

backup_files eltern-wp backup/eltern-wp-files
backup_db \
  eltern-wp \
  "<%= config['eltern-wp']['source_db'] %>" \
  "<%= config['eltern-wp']['source_user'] %>" \
  "<%= config['eltern-wp']['source_password'] %>" \
  backup/eltern-wp-db

backup_files freunde-wp backup/freunde-wp-files
backup_db \
  freunde-wp \
  "<%= config['freunde-wp']['source_db'] %>" \
  "<%= config['freunde-wp']['source_user'] %>" \
  "<%= config['freunde-wp']['source_password'] %>" \
  backup/freunde-wp-db

backup_files geb3 backup/geb3-files
backup_db \
  geb3 \
  "<%= config['geb3']['source_db'] %>" \
  "<%= config['geb3']['source_user'] %>" \
  "<%= config['geb3']['source_password'] %>" \
  backup/geb3-db

backup_files geb-wp backup/geb-wp-files
backup_db \
  geb-wp \
  "<%= config['geb-wp']['source_db'] %>" \
  "<%= config['geb-wp']['source_user'] %>" \
  "<%= config['geb-wp']['source_password'] %>" \
  backup/geb-wp-db
