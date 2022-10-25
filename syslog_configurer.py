import os
import sys


def generate_syslog_config(new_app_directory: str, reload_daemon=True):
    log_directory = new_app_directory + "/log/" 
    if not os.path.isdir(log_directory):
        print("{} has no log directory (expected: {})".format(new_app_directory, log_directory))
        sys.exit(-3)


    splitted = log_directory.split("/")
    app_id = splitted[2].replace('-','_')
    # NOTE: app_id is constructed as follows: <app_name>-<app_version>-<uuid>

    config = """
    source s_{app_id} {{
        file("{log_directory}/syslog");
        file("{log_directory}/application.log");
    }};

    log {{
        source(s_{app_id});
        destination(d_all_logs);
    }};\n
    """.format(log_directory = log_directory, 
               app_id = app_id)

    with open('/etc/syslog-ng/conf.d/app-{app_id}.conf_custom'.format(app_id = app_id),'w') as syslog_config_file:
        syslog_config_file.write(config)

    if reload_daemon:
        os.system("/usr/sbin/syslog-ng-ctl reload")


def create_main_syslog_config(loggly_auth_token):
    config = """
    ### START Loggly Configuration
    template LogglyFormat {{
        template("<${{PRI}}>1 ${{ISODATE}} ${{HOST}} ${{PROGRAM}} ${{PID}} ${{MSGID}} [{loggly_auth_token}@41058] $MSG\\n");
        template_escape(no);
    }};

    destination d_all_logs {{
        tcp("logs-01.loggly.com" port(6514)
        tls(peer-verify(required-untrusted) ca_dir('/etc/syslog-ng/keys/ca.d/'))
        template(LogglyFormat));
    }};

    ### END Syslog Logging Directives for Loggly (myaccount.loggly.com) ###

    include "/etc/syslog-ng/conf.d/host.conf_custom";
    include "/etc/syslog-ng/conf.d/app-*.conf_custom";
    """.format(loggly_auth_token = loggly_auth_token)

    with open('/etc/syslog-ng/conf.d/syslog-ng-main.conf','w') as config_file:
        config_file.write(config)

def get_immediate_subdirectories(a_dir):
    """
    Returns list of absolute path of all immediate sub directories.
    Thanks to http://stackoverflow.com/questions/800197/get-all-of-the-immediate-subdirectories-in-python
    """
    return [ a_dir + '/' + name for name in os.listdir(a_dir)
        if os.path.isdir(os.path.join(a_dir, name))]

def create_syslog_config_for_already_existing_apps():
    app_directories = get_immediate_subdirectories('/app')
    for app_dir in app_directories:
         generate_syslog_config(app_dir, False)

def main():
    
    if len(sys.argv) < 3:
        print('not enough arguments')
        sys.exit(-5)
    
    function = sys.argv[1]

    if function == '--new_app':
        new_app_directory = sys.argv[2]
        if not os.path.isdir(new_app_directory):
            print("{} is not a directory or does not exist".format(new_app_directory))
            sys.exit(-1)
        generate_syslog_config(new_app_directory)
    elif function == '--new_main':
        loggly_auth_token = sys.argv[2]
        if not loggly_auth_token:
            print("no Loggly AUTH token specified")
            exit(-2)

        create_main_syslog_config(loggly_auth_token)
        create_syslog_config_for_already_existing_apps()
    else:
        print ("unsupported function '{}'".format(function))
        exit(-4)


if __name__ == '__main__':
    main()
