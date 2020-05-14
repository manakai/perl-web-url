$Web::URL::_Defs = {
          'default_port' => {
                              'ftp' => '21',
                              'gopher' => '70',
                              'http' => '80',
                              'https' => '443',
                              'ws' => '80',
                              'wss' => '443'
                            },
          'origin' => {
                        'blob' => 'nested',
                        'file' => 'file',
                        'ftp' => 'hostport',
                        'http' => 'hostport',
                        'https' => 'hostport',
                        'ws' => 'hostport',
                        'wss' => 'hostport'
                      }
        };
;