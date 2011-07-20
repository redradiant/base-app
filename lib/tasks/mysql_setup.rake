require 'erb'
require 'yaml'

YAML::ENGINE.yamler= 'syck'
raise "Rails not loaded!" unless File.exist?("#{Rails.root}/config/database.yml")

$dbinfo = YAML::load(ERB.new(IO.read("#{Rails.root}/config/database.yml")).result)

class MysqlSimple

  attr_accessor :mysqlstring

  def initialize(string = "mysql -u root mysql")
    @mysqlstring = string
  end

  def do(command)
    command.gsub!(/[\;\s\r\n]+$/, '')
    command.gsub!(/\"/, '\"')
    puts "Executing: #{command}"
    res = `#{mysqlstring} -e "#{command};" 2>&1`
    $stdout.flush
  end

end

$conn = MysqlSimple.new
$hn = `hostname`
$hn.gsub!(/\s/, '')
$envs = $dbinfo.each_key
$dbs = [] # $dbinfo.each_value.collect { |c| c['database'] }.compact

namespace :mysql_setup do

  desc "Setup MySQL user for this app"
  task :user => :environment do
    raise "No #{Rails.env} username" unless $dbinfo[Rails.env]['username'] =~ /\w/
    setup_user_for_databases($dbinfo[Rails.env]['username'],$dbinfo[Rails.env]['password'], $dbs)
  end

  desc "Setup MySQL databases for this app"
  task :databases => :environment do
    
    $dbinfo.each_value do |config|
      next unless (config['database'] =~ /\w/ && config['adapter'] =~ /mysql/i)
      setup_database(config['database'])
      $dbs << config['database']
    end
  end

  desc "Setup databases and user for this application."
  task :full => [ 'mysql_setup:databases', 'mysql_setup:user' ]

  def setup_database(name)
    $conn.do("DROP DATABASE IF EXISTS #{name}")
    $conn.do("CREATE DATABASE #{name}")
  end

  def setup_user_for_databases(username, password, *databases)
    $conn.do "DROP USER '#{username}'"
    $conn.do "FLUSH PRIVILEGES;"
    $conn.do "CREATE USER '#{username}' IDENTIFIED BY '#{password}'"
    databases.flatten.each do |db|
      $conn.do "GRANT ALL PRIVILEGES ON #{db}.* TO '#{username}'@'%' IDENTIFIED BY '#{password}'"
      $conn.do "GRANT ALL PRIVILEGES ON #{db}.* TO '#{username}'@'localhost' IDENTIFIED BY '#{password}'"
      $conn.do "GRANT ALL PRIVILEGES ON #{db}.* TO '#{username}'@'#{$hn}' IDENTIFIED BY '#{password}'"
    end
    $conn.do "FLUSH PRIVILEGES;"
  end

end
