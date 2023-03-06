#!/usr/bin/env fish

tar -czf secrets.tgz secrets

set token (op signin -f --raw)

op document edit secrets secrets.tgz --session $token
op document edit inventory inventory.cfg --session $token
