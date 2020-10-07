# create secrets to use for encryption and signing of JWT
# Peter Ramm, 2020-10-07

DEFAULT_SECRET_KEY_BASE_FILE = File.join(Rails.root, 'config', 'secret_key_base')

# use local variables
begin
  secret_key_base = nil                                                         # set later

  if File.exists?(DEFAULT_SECRET_KEY_BASE_FILE)                                 # look for generated file at first
    secret_key_base = File.read(DEFAULT_SECRET_KEY_BASE_FILE)
    Rails.logger.info "Secret key base read from default file location '#{DEFAULT_SECRET_KEY_BASE_FILE}' (#{secret_key_base.length} chars)"
    Rails.logger.error "Secret key base file at default location '#{DEFAULT_SECRET_KEY_BASE_FILE}' is empty!" if secret_key_base.nil? || secret_key_base == ''
    Rails.logger.warn "Secret key base from file at default location '#{DEFAULT_SECRET_KEY_BASE_FILE}' is too short! Should have at least 128 chars!" if secret_key_base.length < 128
  end

  if ENV['SECRET_KEY_BASE_FILE']                                              # User-provided secrets file
    if File.exists?(ENV['SECRET_KEY_BASE_FILE'])
      secret_key_base = File.read(ENV['SECRET_KEY_BASE_FILE'])
      Rails.logger.info "Secret key base read from file '#{ENV['SECRET_KEY_BASE_FILE']}' pointed to by SECRET_KEY_BASE_FILE environment variable (#{secret_key_base.length} chars)"
      Rails.logger.error "Secret key base file pointed to by SECRET_KEY_BASE_FILE environment variable is empty!" if secret_key_base.nil? || secret_key_base == ''
      Rails.logger.warn "Secret key base from file pointed to by SECRET_KEY_BASE_FILE environment variable is too short! Should have at least 128 chars!" if secret_key_base.length < 128
    else
      Rails.logger.error "Secret key base file pointed to by SECRET_KEY_BASE_FILE environment variable does not exist (#{ENV['SECRET_KEY_BASE_FILE']})!"
    end
  end

  if ENV['SECRET_KEY_BASE']                                                   # Env rules over file
    secret_key_base = ENV['SECRET_KEY_BASE']
    Rails.logger.info "Secret key base read from environment variable SECRET_KEY_BASE (#{secret_key_base.length} chars)"
    Rails.logger.warn "Secret key base from SECRET_KEY_BASE environment variable is too short! Should have at least 128 chars!" if secret_key_base.length < 128
  end

  if secret_key_base.nil? || secret_key_base == ''
    Rails.logger.warn "Neither SECRET_KEY_BASE nor SECRET_KEY_BASE_FILE provided!"
    Rails.logger.warn "Temporary encryption key for SECRET_KEY_BASE is generated and stored in local filesystem!"
    Rails.logger.warn "This key is valid only for the lifetime of this running Panorama instance and is not persistent!!!"
    secret_key_base = Random.rand 99999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999999
    File.write(DEFAULT_SECRET_KEY_BASE_FILE, secret_key_base)
  end

  raise "create_secrets.rb: No base value for SECRET_KAY_BASE found, aborting!" if secret_key_base.nil? # should never occur

  secrets_file = File.join(Rails.root, 'config', 'secrets.yml')
  rails_env = ENV['RAILS_ENV'] || 'production'
  content = "# File generated by config/initializers/create_secrets.rb

#{rails_env}:
    secret_key_base: \"#{secret_key_base.to_s.strip}\"
  "
  begin
    File.write(secrets_file, content)
  rescue Exception => e
    puts "Error creating secrets file '#{secrets_file}'\n#{e.class}: #{e.message}"
  end


end



