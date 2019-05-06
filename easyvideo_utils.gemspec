Gem::Specification.new do |s|
  s.name = 'easyvideo_utils'
  s.version = '0.2.1'
  s.summary = 'A wrapper for ffmpeg to make basic video editing easier.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/easyvideo_utils.rb']
  s.add_runtime_dependency('c32', '~> 0.2', '>=0.2.0')  
  s.add_runtime_dependency('subunit', '~> 0.4', '>=0.4.0')
  s.signing_key = '../privatekeys/easyvideo_utils.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/easyvideo_utils'
end
