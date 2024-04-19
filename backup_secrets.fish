#!/usr/bin/env fish

tar -czf secrets.tgz secrets

op signin

op document edit secrets secrets.tgz
op document edit inventory inventory.cfg
