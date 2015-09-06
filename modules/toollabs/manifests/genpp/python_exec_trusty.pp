# Class: toollabs::genpp::python_exec_trusty
#
# This file was auto-generated by genpp.py using the following command:
# python.py
#
# Please do not edit manually!

class toollabs::genpp::python_exec_trusty {
    package { [
        'python-apport',        # 2.14.1
        'python3-apport',       # 2.14.1
        'python-babel',         # 1.3
        'python3-babel',        # 1.3
        'python-beautifulsoup', # 3.2.1
        # python3-beautifulsoup is not available
        'python-bottle',        # 0.12.0
        'python3-bottle',       # 0.12.0
        'python-celery',        # 3.1.6
        # python3-celery is not available
        'python-egenix-mxdatetime', # 3.2.7
        # python3-egenix-mxdatetime is not available
        'python-egenix-mxtools', # 3.2.7
        # python3-egenix-mxtools is not available
        'python-enum34',        # 0.9.23
        'python3-enum34',       # 0.9.23
        'python-flask',         # 0.10.1
        'python3-flask',        # 0.10.1
        'python-flask-login',   # 0.2.6
        # python3-flask-login is not available
        'python-flickrapi',     # 1.2
        # python3-flickrapi is not available
        'python-flup',          # 1.0.2
        # python3-flup is not available
        'python-gdal',          # 1.10.1
        'python3-gdal',         # 1.10.1
        'python-gdbm',          # 2.7.5
        'python3-gdbm',         # 3.4.0
        'python-genshi',        # 0.7
        'python3-genshi',       # 0.7
        'python-genshi-doc',    # 0.7
        # python3-genshi-doc is not available
        'python-geoip',         # 1.2.4
        # python3-geoip is not available
        'python-gevent',        # 1.0
        # python3-gevent is not available
        'python-gi',            # 3.12.0
        'python3-gi',           # 3.12.0
        'python-greenlet',      # 0.4.2
        'python3-greenlet',     # 0.4.2
        'python-httplib2',      # 0.8
        'python3-httplib2',     # 0.8
        'python-imaging',       # 2.3.0
        'python3-imaging',      # 2.3.0
        'python-ipaddr',        # 2.1.10
        'python3-ipaddr',       # 2.1.10
        'python-irclib',        # 0.4.8
        # python3-irclib is not available
        'python-keyring',       # 3.5
        'python3-keyring',      # 3.5
        'python-launchpadlib',  # 1.10.2
        # python3-launchpadlib is not available
        'python-lxml',          # 3.3.3
        'python3-lxml',         # 3.3.3
        'python-magic',         # 1:5.14
        'python3-magic',        # 1:5.14
        'python-matplotlib',    # 1.3.1
        'python3-matplotlib',   # 1.3.1
        'python-mysql.connector', # 1.1.6
        'python3-mysql.connector', # 1.1.6
        'python-mysqldb',       # 1.2.3
        # python3-mysqldb is not available
        'python-newt',          # 0.52.15
        'python3-newt',         # 0.52.15
        'python-nose',          # 1.3.1
        'python3-nose',         # 1.3.1
        'python-opencv',        # 2.4.8
        # python3-opencv is not available
        'python-pil',           # 2.3.0
        'python3-pil',          # 2.3.0
        'python-problem-report', # 2.14.1
        'python3-problem-report', # 2.14.1
        'python-pycountry',     # 0.14.1
        # python3-pycountry is not available
        'python-pydot',         # 1.0.28
        # python3-pydot is not available
        'python-pyexiv2',       # 0.3.2
        # python3-pyexiv2 is not available
        'python-pygments',      # 1.6
        'python3-pygments',     # 1.6
        'python-pyicu',         # 1.5
        'python3-pyicu',        # 1.5
        'python-pyinotify',     # 0.9.4
        'python3-pyinotify',    # 0.9.4
        'python-requests',      # 2.2.1
        'python3-requests',     # 2.2.1
        'python-rsvg',          # 2.32.0
        # python3-rsvg is not available
        'python-scipy',         # 0.13.3
        'python3-scipy',        # 0.13.3
        # python-socketio-client is not available
        # python3-socketio-client is not available
        'python-sqlalchemy',    # 0.8.4
        'python3-sqlalchemy',   # 0.8.4
        'python-svn',           # 1.7.8
        # python3-svn is not available
        'python-twisted',       # 13.2.0
        # python3-twisted is not available
        'python-twitter',       # 1.1
        # python3-twitter is not available
        'python-unicodecsv',    # 0.9.4
        # python3-unicodecsv is not available
        'python-unittest2',     # 0.5.1
        # python3-unittest2 is not available
        'python-virtualenv',    # 1.11.4
        # python3-virtualenv is not available
        'python-wadllib',       # 1.3.2
        'python3-wadllib',      # 1.3.2
        'python-webpy',         # 1:0.37
        # python3-webpy is not available
        'python-werkzeug',      # 0.9.4
        'python3-werkzeug',     # 0.9.4
        'python-yaml',          # 3.10
        'python3-yaml',         # 3.10
        'python-zbar',          # 0.10
        # python3-zbar is not available
        'python-zmq',           # 14.0.1
        'python3-zmq',          # 14.0.1
    ]:
        ensure => latest,
    }
}
