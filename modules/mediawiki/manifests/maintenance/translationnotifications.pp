class mediawiki::maintenance::translationnotifications( $ensure = present ) {
    # Should there be crontab entry for each wiki,
    # or just one which runs the scripts which iterates over
    # selected set of wikis?

    cron { 'translationnotifications-metawiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki >> /var/log/translationnotifications/digests.log 2>&1',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 0,
    }

    cron { 'translationnotifications-mediawikiwiki':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        command => '/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki >> /var/log/translationnotifications/digests.log 2>&1',
        weekday => 1, # Monday
        hour    => 10,
        minute  => 5,
    }

    file { '/var/log/translationnotifications':
        ensure => ensure_directory($ensure),
        owner  => $::mediawiki::users::web,
        group  => 'wikidev',
        mode   => '0664',
    }

    $log_ownership_user = $::mediawiki::users::web
    logrotate::conf { 'l10nupdate':
        ensure  => $ensure,
        content => template('mediawiki/maintenance/logrotate.d_translationnotifications.erb'),
    }
}
