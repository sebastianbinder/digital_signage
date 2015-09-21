desc 'Run all deployment rake tasks'
task :post_deploy => [
  'deploy:precompile_assets',
  'deploy:tell_newrelic',
]
