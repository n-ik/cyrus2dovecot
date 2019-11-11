#!/bin/sh

set -x

domain=$1

if [ -z "$domain"  ]; then
  echo
  echo 'Usage:'
  echo "  $0 <domain> "
  echo
  exit 1
fi

in=old_mailboxes/var/spool/imap/domain/*/$domain/*/*/         # Cyrus INBOXes.
out=/data/vmail                                               # Dovecot Maildirs.
sieve=old_sieve/var/lib/imap/sieve/domain/?/$domain/?         # Dovecot sieve.
log=/tmp/mail-migration-conversion.log                        # Log of successful conversions.
err=/tmp/mail-migration-error.log                             # Log of conversion errors.

mkdir -p $out/$domain                                         # Create domain folder

for u in `find $in/. \! -name . -prune -exec basename \{\} \;`
do

    ./cyrus2dovecot --cyrus-inbox $in/$u                             \
                    --dovecot-inbox $out/$domain/$u@$domain/maildir  \
                    --cyrus-sieve $sieve/$u/roundcube.script         \
                    --edit-foldernames 's/^\.//'                     \
                    --edit-foldernames 's/\./\//g'                   \
                    $u 2>&1 >>$log | tee -a $err >&2

    mv $out/$domain/$u@$domain/maildir/sieve $out/$domain/$u@$domain/                               # Fix sieve path issue
    ln -s $out/$domain/$u@$domain/sieve/managesieve.sieve  $out/$domain/$u@$domain/.dovecot.sieve   # ""                ""
done

chown -R vmail:vmail $out/$domain                               # Fix owner
chmod -R 700 $out/$domain
