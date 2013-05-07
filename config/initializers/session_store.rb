# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_fedena_session',
  :secret      => 'sdlrewrew90rk09jsdfs3423jfds89034jlsdkdsfsmnvkhfytemmc783knsnvccvfgds453hd64hdu3kj3io328um1r6h7jd9ks0l3d7cb9',
  :expire_after => 10.minutes
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
