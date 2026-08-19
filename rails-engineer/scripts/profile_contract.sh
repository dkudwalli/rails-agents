#!/usr/bin/env bash

PROFILE_FIELDS=(
  architecture
  testing
  css
  views
  database
  ids
  authorization
  authentication
  runtime
  assets
  tenancy
  deployment
  workflow
  app_kind
)

profile_allowed_values() {
  case "$1" in
    architecture) printf '%s' 'layered rich-models' ;;
    testing) printf '%s' 'rspec minitest' ;;
    css) printf '%s' 'tailwind plain' ;;
    views) printf '%s' 'viewcomponent erb-partials' ;;
    database) printf '%s' 'postgres sqlite mysql' ;;
    ids) printf '%s' 'uuidv7 integer' ;;
    authorization) printf '%s' 'pundit scoped-model' ;;
    authentication) printf '%s' 'secure-password session-record' ;;
    runtime) printf '%s' 'solid redis-resque' ;;
    assets) printf '%s' 'importmap node-bundler' ;;
    tenancy) printf '%s' 'single multi' ;;
    deployment) printf '%s' 'kamal docker-procfile' ;;
    workflow) printf '%s' 'sdd conventional' ;;
    app_kind) printf '%s' 'new existing' ;;
    *) return 1 ;;
  esac
}
