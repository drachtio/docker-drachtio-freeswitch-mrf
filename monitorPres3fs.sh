#!/bin/sh
inotifywait -m -e create -e close_write -e moved_to --format '%f' /var/pres3fs | while read FILE
do
    echo "file moved /var/pres3fs/$FILE -> /var/s3fs/$FILE"
    cp /var/pres3fs/$FILE /var/s3fs/$FILE
done