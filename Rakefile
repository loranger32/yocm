require "rake/testtask"
require "standard/rake"
require "dotenv"
Dotenv.load

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
  Sequel.connect(db_url) do |db|
    if Sequel::Migrator.is_current?(db, MIGRATIONS_PATH)
      puts "No pending migration in #{db_name}"
    else
      puts "There are pending migrations in #{db_name}. Run 'rake db:migrate' to apply them"
    end
  end
end

def revert_all_migrations(db_url, db_name)
  Sequel.connect(db_url) do |db|
    Sequel::Migrator.run(db, MIGRATIONS_PATH, target: 0)
    puts "All migrations reverted on #{db_name}"
  end
end

def migrate_db(db_url, db_name, version)
  Sequel.connect(db_url) do |db|
    Sequel::Migrator.run(db, MIGRATIONS_PATH, target: version)
    puts "#{db_name} migrated"
  end
end

desc "Access an irb console with database connection initialized"
task :c do
  system("irb -r ./db/db.rb")
end

namespace :db do
  desc "Run migrations on production DB"
  task :migrate, [:version] do |_, args|
    version = args[:version].to_i if args[:version]
    migrate_db(ENV["DATABASE_URL"], "Production DB", version)
  end

  desc "Revert all migrations on production DB"
  task :reset do
    puts "Are you sure ? It will erase ALL data already present in the PRODUCTION DB"
    puts "Please confirm you made a backup of the DB ('Yes/no')"
    answer = $stdin.gets.chomp
    if answer == "Yes"
      revert_all_migrations(ENV["DATABASE_URL"], "Production DB")
    else
      puts "Abort reverting PRODUCTION DB"
    end
  end

  desc "Check pending migrations on production DB"
  task :pending do
    check_pending_migration(ENV["DATABASE_URL"], "Production DB")
  end

  desc "Dump database schema with timestamp"
  task :schema do
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    destination = File.join(SCHEMA_PATH, "001_schema_#{timestamp}.rb")
    system "rm #{SCHEMA_PATH}/*"
    system("sequel -D #{ENV["DATABASE_URL"]} > #{destination}")
    puts "Schema dumped to #{destination}"
  end

  # Depending on your Postgres settings, it may ask you the password to access the DB
  desc "Backup Production DB"
  task :backup do
    time_stamp = Time.now.strftime("%Y%m%d%H%M%S")
    backup_path = File.join(ENV["DB_BACKUP_DIR"], "dcap_db_#{time_stamp}")
    `pg_dump -F p yocm > #{backup_path}`
    puts "Successfully created backup of production DB at #{backup_path}"
  end

  # TO BE DELETED (or make it a CLI command - already a GUI command)
  desc "Delete publications before date (\"YYYY-MM-DD\")"
  task :delete_pub, [:date] do |_, args|
    date = Date.parse(args[:date])
    Sequel.connect(ENV["DATABASE_URL"]) do |db|
      puts "Are you sure ? All pub older than #{date} will be permanently deleted ('Yes/no')"
      answer = $stdin.gets.chomp

      if %w[yes Yes y].include?(answer)
        number_deleted = db[:publications].where(Sequel[:pub_date] < date).delete
        puts "#{number_deleted} publications successfully deleted."
      else
        puts "Delete operation aborted"
      end
    end
  end

  namespace :test do
    desc "Run migrations on test DB"
    task :migrate, [:version] do |_, args|
      version = args[:version].to_i if args[:version]
      migrate_db(ENV["TEST_DATABASE_URL"], "Test DB", version)
    end

    desc "Revert all migrations on test DB"
    task :reset do
      revert_all_migrations(ENV["TEST_DATABASE_URL"], "Test DB")
    end

    desc "Check pending migrations on test database"
    task :pending do
      check_pending_migration(ENV["TEST_DATABASE_URL"], "TEST DB")
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
      migrate_db(ENV["DEV_DATABASE_URL"], "Development DB", version)
    end

    desc "Revert all migrations on development DB"
    task :reset do
      revert_all_migrations(ENV["DEV_DATABASE_URL"], "Development DB")
    end

    desc "Check pending migrations on development DB"
    task :pending do
      check_pending_migration(ENV["DEV_DATABASE_URL"], "Development DB")
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
