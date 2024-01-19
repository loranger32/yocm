require "rake/testtask"
require "standard/rake"
require "dotenv"
Dotenv.load

DB_NAME = "yocm.db"
DEV_DB_NAME = "yocm_dev.db"
TEST_DB_NAME = "yocm_test.db"

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run tests"
task :default => :test

desc "Start development server (rerun enabled)"
task :ds do
  exec "bundle exec rerun --ignore 'test/*' rackup app/config.ru"
end

desc "Start classic server"
task :s do
  system "bundle exec rackup app/config.ru"
end

desc "Generate random base64 string of 64 bytes length"
task :random do
  require "securerandom"
  random_string = SecureRandom.base64(48)
  puts "Random string of 64 bytes length: #{random_string}"
end

require "sequel/core"
require "sequel"

Sequel.extension :migration

MIGRATIONS_PATH = File.expand_path("db/migrations", __dir__)
SCHEMA_PATH = File.expand_path("db/schema", __dir__)

def check_pending_migration(db_url, db_name)
  Sequel.sqlite(db_url) do |db|
    if Sequel::Migrator.is_current?(db, MIGRATIONS_PATH)
      puts "No pending migration in #{db_name}"
    else
      puts "There are pending migrations in #{db_name}. Run 'rake db:[all?|test?|dev?|]migrate' to apply them"
    end
  end
end

def revert_all_migrations(db_url, db_name)
  Sequel.sqlite(db_url) do |db|
    Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
    puts "All migrations reverted on #{db_name}"
  end
end

def migrate_db(db_url, db_name, version)
  Sequel.sqlite(db_url) do |db|
    Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
    puts "#{db_name} migrated"
  end
end

desc "Access an irb console with database connection initialized"
task :c do
  system("irb -r ./db/db.rb")
end

namespace :db do
  base_db_path = if ENV["BASE_DB_PATH"] && File.absolute_path?(ENV["BASE_DB_PATH"])
    ENV["BASE_DB_PATH"]
  else
    "db"
  end

  production_db_url = File.join(base_db_path, DB_NAME)
  dev_db_url        = File.join(base_db_path, DEV_DB_NAME)

  # test db is always in db folder
  test_db_url       = File.join("db", TEST_DB_NAME)

  desc "Run migrations on production DB"
  task :migrate, [:version] do |_, args|
    version = args[:version].to_i if args[:version]
    migrate_db(production_db_url, "Production DB", version)
  end

  desc "Revert all migrations on production DB"
  task :reset do
    puts "Are you sure ? It will erase ALL data already present in the PRODUCTION DB"
    puts "Please confirm you made a backup of the DB ('Yes/no')"
    answer = $stdin.gets.chomp
    if answer == "Yes"
      revert_all_migrations(production_db_url, "Production DB")
    else
      puts "Abort reverting PRODUCTION DB"
    end
  end

  desc "Check pending migrations on production DB"
  task :pending do
    check_pending_migration(production_db_url, "Production DB")
  end

  desc "Dump database schema with timestamp"
  task :schema do
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    destination = File.join(SCHEMA_PATH, "001_schema_#{timestamp}.rb")
    #system "rm #{SCHEMA_PATH}/*"
    system("sequel -D sqlite://#{production_db_url} > #{destination}")
    puts "Schema dumped to #{destination}"
  end

  desc "Backup Production DB"
  task :backup do
    unless File.absolute_path?(ENV["DB_BACKUP_DIR"])
      abort("The directory path for the backups must be an absolute path, got a relative instead - check your env variable")
    end

    time_stamp = Time.now.strftime("%Y%m%d%H%M%S")
    backup_path = File.join(ENV["DB_BACKUP_DIR"], "yocm_db_#{time_stamp}")
    `cp #{production_db_url} #{backup_path}`
    puts "Successfully created backup of production DB at #{backup_path}"
  end

  namespace :test do
    desc "Run migrations on test DB"
    task :migrate, [:version] do |_, args|
      version = args[:version].to_i if args[:version]
      migrate_db(test_db_url, "Test DB", version)
    end

    desc "Revert all migrations on test DB"
    task :reset do
      revert_all_migrations(test_db_url, "Test DB")
    end

    desc "Check pending migrations on test database"
    task :pending do
      check_pending_migration(test_db_url, "Test DB")
    end

    desc "Access an irb console with test database connection initialized"
    task :console do
      system("RAKE_CONSOLE_ENV=test irb -r ./db/db.rb")
    end
  end

  namespace :dev do
    desc "Run migrations on development DB"
    task :migrate, [:version] do |_, args|
      version = args[:version].to_i if args[:version]
      migrate_db(dev_db_url, "Development DB", version)
    end

    desc "Revert all migrations on development DB"
    task :reset do
      revert_all_migrations(dev_db_url, "Development DB")
    end

    desc "Check pending migrations on development DB"
    task :pending do
      check_pending_migration(dev_db_url, "Development DB")
    end

    desc "Access an irb console with development database connection initialized"
    task :console do
      system("RAKE_CONSOLE_ENV=development irb -r ./db/db.rb")
    end
  end

  namespace :all do
    desc "Check pending migrations on all DBs"
    task pending: [:"db:pending", :"db:dev:pending", :"db:test:pending"]

    desc "Migrate all DBs to latest version"
    task migrate: [:"db:migrate", :"db:dev:migrate", :"db:test:migrate"]
  end
end
