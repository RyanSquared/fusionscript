#!/bin/sh

git fetch luavm && \
git merge -s subtree --squash luavm/master && \
git commit -m \
"update luavm subtree to {$(git log luavm/master --oneline -1 --color=never)}"
