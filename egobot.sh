#!/bin/sh

echo "Egobot looper v0.1"

while [ 1 ]; do
  luvit egobot.lua
  code=$?
  echo "Egobot exited with $code:"
  case $code in
    42)
      echo "Updating Egobot..."
      git pull
    ;;
    43)
      echo "Restarting Egobot..."
    ;;
    255)
      echo "Restarting Egobot after crash..."
    ;;
    *)
      echo "Exiting Egobot..."
      break
    ;;
  esac
done