# frozen_string_literal: true

command :serve do |c|
  c.syntax = 'pk serve [PASSNAME]'
  c.summary = 'Serves a .pkpass archive from a webserver'
  c.description = ''

  c.example 'description', 'pk archive mypass'
  c.option '-c', '--certificate /path/to/cert.pem', 'Pass certificate'
  c.option '-p', '--[no]-password', 'Prompt for certificate password'
  c.option '-H', '--host [HOST]', 'Host to bind to'

  c.action do |args, options|
    determine_directory! unless @directory = args.first
    validate_directory!

    @certificate = options.certificate
    validate_certificate!

    @password = ask('Enter certificate password:') { |q| q.echo = false } if options.password

    Dubai::Passbook.certificate = @certificate
    Dubai::Passbook.password = @password

    Dubai::Server.set :directory, @directory

    Dubai::Server.set :bind, options.host if options.host

    Dubai::Server.run!
  end
end

# alias_command :serve, :preview
# alias_command :serve, :s

private

def determine_directory!
  files = Dir['*/pass.json']
  @directory ||= case files.length
                 when 0 then nil
                 when 1 then File.dirname(files.first)
                 else
                   @directory = choose 'Select a directory:', *files.collect { |f| File.dirname(f) }
                 end
end

def validate_directory!
  say_error('Missing argument') && abort if @directory.nil?
  say_error("Directory #{@directory} does not exist") && abort unless File.directory?(@directory)
  say_error("Directory #{@directory} is not valid pass") && abort unless File.exist?(File.join(@directory, 'pass.json'))
end

def validate_certificate!
  say_error('Missing or invalid certificate file') && abort if @certificate.nil? || !File.exist?(@certificate)
end
