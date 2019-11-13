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

# Create domain folder
mkdir -p $out/$domain

for u in `find $in/. \! -name . -prune -exec basename \{\} \;`
do
    ./cyrus2dovecot --cyrus-inbox $in/$u                             \
                    --dovecot-inbox $out/$domain/$u@$domain/maildir  \
                    --cyrus-sieve $sieve/$u/roundcube.script         \
                    --edit-foldernames 's/^\.//'                     \
                    --edit-foldernames 's/\./\//g'                   \
                    $u 2>&1 >>$log | tee -a $err >&2

    # Fix sieve path issue
    cp -rf $out/$domain/$u@$domain/maildir/sieve $out/$domain/$u@$domain/
    rm -rf $out/$domain/$u@$domain/maildir/sieve
    ln -sf $out/$domain/$u@$domain/sieve/managesieve.sieve  $out/$domain/$u@$domain/.dovecot.sieve
done

# Fix owner
chown -R vmail:vmail $out/$domain
chmod -R 700 $out/$domain
