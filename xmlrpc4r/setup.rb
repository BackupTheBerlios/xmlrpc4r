#
# setup.rb
#
#   Copyright (c) 2000 Minero Aoki <aamine@dp.u-netsurf.ne.jp>
#
#   This program is free software.
#   You can distribute/modify this program under the terms of
#   the GNU General Public License version 2 or later.
#

require 'tempfile'
require 'rbconfig'


class InstallError < StandardError; end


class Installer

  Version   = '2.0.0'
  Copyright = 'Copyright (c) 2000 Minero Aoki'


  CONFIG = ::Config::CONFIG

  RUBY          = CONFIG['ruby_install_name']

  MAJOR_VERSION = CONFIG['MAJOR'].to_i
  MINOR_VERSION = CONFIG['MINOR'].to_i
  TEENY_VERSION = CONFIG['TEENY'].to_i
  VERSION = CONFIG['MAJOR'] + '.' + CONFIG['MINOR']

  BINDIR     = File.join( CONFIG['bindir'] )
  LIBDIR     = File.join( CONFIG['libdir'], 'ruby' )
  DATADIR    = File.join( CONFIG['datadir'] )

  ARCH       = CONFIG['arch']

  NEW_LIB_PATH = ((MAJOR_VERSION >= 2) or
                  ((MAJOR_VERSION == 1) and
                   ((MINOR_VERSION >= 5) or
                    ((MINOR_VERSION == 4) and (TEENY_VERSION >= 4)))))
    
  if NEW_LIB_PATH then
    SITELIBDIR = File.join( LIBDIR, 'site_ruby', VERSION )
  else
    SITELIBDIR = File.join( LIBDIR, VERSION, 'site_ruby' )
  end

  STDLIBDIR  = File.join( LIBDIR, VERSION )
  RBDIR      = File.join( STDLIBDIR )
  SODIR      = File.join( STDLIBDIR, ARCH )

  SITE_RB    = File.join( SITELIBDIR )
  SITE_SO    = File.join( SITELIBDIR, ARCH )

  RUBY_PATH  = File.join( BINDIR, RUBY )

  DLEXT      = CONFIG['DLEXT']


  #
  # name => [ default, argument-name, discription ]
  #
  OPTIONS = {
    'bin-dir'   => [ BINDIR,
                     'path',
                     'directory for binary' ],
    'rb-dir'    => [ SITE_RB,
                     'path',
                     'directory for ruby script' ],
    'so-dir'    => [ SITE_SO,
                     'path',
                     'directory for ruby extention' ],
    'data-dir'  => [ DATADIR,
                     'path',
                     'directory for data' ],
    'ruby-path' => [ RUBY_PATH,
                     'path',
                     'path to ruby interpreter' ],
    'make-prog' => [ 'make',
                     'name',
                     'make program for ruby extention' ],
    'with'      => [ '',
                     'name,name...',
                     'package name(s) you want to install' ],
    'without'   => [ '',
                     'name,name...',
                     'package name(s) you do not want to install' ]
  }

  OPTION_ORDER = %w( bin-dir rb-dir so-dir ruby-path make-prog with without )

  TASKS = {
    'config'       => 'set config option',
    'setup'        => 'compile extention or else',
    'install'      => 'install packages',
    'clean'        => "do `make clean' for each extention",
    'dryrun'       => 'test run',
    'show'         => 'show current configuration'
  }

  TASK_ORDER = %w( config setup install clean dryrun show )

  TYPES = %w( bin lib ext share )


  def initialize( argv )
    @verbose = true
    @config = {}
    @task = nil
    @other_args = []

    configure
    parsearg argv.dup
  end

  attr :config
  attr :task


  ConfigFile = 'config.save'

  def configure
    OPTIONS.each do |k,v|
      @config[ k ] = v[0]
    end
    if File.file? ConfigFile then
      File.foreach( ConfigFile ) do |line|
        k, v = line.split( '=', 2 )
        set_config k.strip, v.strip
      end
    end
  end

  def set_config( k, v )
    if OPTIONS[k][1] == 'path' then
      @config[k] = File.expand_path(v)
    else
      @config[k] = v
    end
  end

  def parsearg( argv )
    tasks = /\A(?:#{TASKS.keys.join '|'})\z/
    arg = argv.shift

    case arg
    when /\A\w+\z/
      unless tasks === arg then
        raise InstallError, "wrong task: #{arg}"
      end
      @task = arg

    when '-h', '--help'
      print_usage $stdout
      exit 0

    when '-v', '--version'
      puts "setup.rb version #{Version}"
      exit 0
    
    when '--copyright'
      puts Copyright
      exit 0

    else
      raise InstallError, "unknown global option '#{arg}'"
    end

    unless argv.empty? then
      mid = "parsearg_#{@task}"
      unless respond_to? mid then
        raise InstallError, "#{@task}:  unknown options: #{argv.join ' '}"
      end
      __send__ mid, argv
    end
    check_packdesig
  end

  def parsearg_config( args )
    opts = /\A--(#{OPTIONS.keys.join '|'})=/

    args.each do |i|
      unless m = opts.match(i) then
        raise InstallError, "config: unknown option #{i}"
      end
      name = m[1]
      ar   = m.post_match.strip
      set_config name, ar
    end
  end

  def parsearg_install( args )
    @no_harm = false
    args.each do |i|
      if i == '--no-harm' then
        @no_harm = true
      else
        raise InstallError, "#{@task}: wrong option #{i}"
      end
    end
  end

  def parsearg_dryrun( args )
    @dr_args = args
  end


  ###
  ### global options
  ###

  def print_usage( out )
    out.puts
    out.puts 'Usage:'
    out.puts '  ruby setup.rb <global option>'
    out.puts '  ruby setup.rb <task> [<task options>]'

    out.puts
    out.puts 'Tasks:'
    TASK_ORDER.each do |name|
      out.printf "  %-10s  %s\n", name, TASKS[name]
    end

    fmt = "  %-20s %s\n"
    out.puts
    out.puts 'Global options:'
    out.printf fmt, '-h,--help', 'print this message'
    out.printf fmt, '-v,--version', 'print version'
    out.printf fmt, '--copyright', 'print copyright'

    out.puts
    out.puts 'Options for config:'
    OPTION_ORDER.each do |name|
      dflt, arg, desc = OPTIONS[name]
      out.printf "  %-20s %s [%s]\n", "--#{name}=#{arg}", desc, dflt
    end

    out.puts
    out.puts 'This archive includes:'
    out.print '  ', packages().join(' '), "\n"

    out.puts
  end


  ###
  ### tasks
  ###

  def execute
    case @task
    when 'config', 'setup', 'install', 'clean'
      tryto @task
    when 'show'
      do_show
    when 'dryrun'
      do_dryrun
    else
      raise 'must not happen'
    end
  end

  def tryto( task )
    $stderr.printf "entering %s phase...\n", task
    begin
      __send__ 'do_' + task
    rescue
      $stderr.printf "%s failed\n", task
      raise
    end
    $stderr.printf "%s done.\n", task
  end

  def do_config
    File.open( ConfigFile, 'w' ) do |f|
      @config.each do |k,v|
        f.printf "%s=%s\n", k, v if v
      end
    end
  end

  def do_show
    OPTION_ORDER.each do |k|
      v = @config[k]
      if not v or v.empty? then
        v = '(not specify)'
      end
      printf "%-10s %s\n", k, v
    end
  end

  def do_setup
    into_dir( 'bin' ) {
      foreach_package do
        Dir.foreach( '.' ) do |fname|
          next unless File.file? fname
          add_rubypath fname
        end
      end
    }
    into_dir( 'ext' ) {
      foreach_package do
        extconf
        make
      end
    }
  end

  def do_install
    into_dir( 'bin' ) {
      foreach_package do |dn, targ|
        install_bin
      end
    }
    into_dir( 'lib' ) {
      foreach_package do |dn, targ|
        install_rb targ
      end
    }
    into_dir( 'ext' ) {
      foreach_package do |dn, targ|
        install_so targ
      end
    }
    into_dir( 'share' ) {
      foreach_package do |dn, targ|
        install_dat targ
      end
    }
  end

  def do_clean
    into_dir( 'ext' ) {
      foreach_package do |dn, targ|
        clean
      end
    }
  end
  
  def do_dryrun
    unless File.directory? 'tmp' then
      $stderr.puts 'setup.rb: setting up temporaly environment...'
      @verbose = $DEBUG
      begin
        @config['bin-dir']  = isdir(File.expand_path('.'), 'tmp', 'bin')
        @config['rb-dir']   = isdir(File.expand_path('.'), 'tmp', 'lib')
        @config['so-dir']   = isdir(File.expand_path('.'), 'tmp', 'ext')
        @config['data-dir'] = isdir(File.expand_path('.'), 'tmp', 'share')
        do_install
      rescue
        rmrf 'tmp'
        $stderr.puts '[BUG] setup.rb bug: "dryrun" command failed'
        raise
      end
    end

    exec @config['ruby-path'],
         '-I' + File.join('.', 'tmp', 'lib'),
         '-I' + File.join('.', 'tmp', 'ext'),
         *@dr_args
  end
  

  ###
  ### lib
  ###

  def into_dir( libn )
    return unless File.directory? libn
    chdir( libn ) {
      yield
    }
  end


  def check_packdesig
    @with    = extract_dirs( @config['with'] )
    @without = extract_dirs( @config['without'] )

    packs = packages
    (@with + @without).each do |i|
      if not packs.include? i and not File.directory? i then
        raise InstallError, "no such package or directory '#{i}'"
      end
    end
  end

  def extract_dirs( s )
    ret = []
    s.split(',').each do |i|
      if /[\*\?]/ === i then
        tmp = Dir.glob(i)
        tmp.delete_if {|d| not File.directory? d }
        if tmp.empty? then
          tmp.push i   # causes error
        else
          ret.concat tmp
        end
      else
        ret.push i
      end
    end

    ret
  end

  def foreach_record( fn = 'PATHCONV' )
    File.foreach( fn ) do |line|
      line.strip!
      next if line.empty?
      a = line.split(/\s+/, 3)
      a[2] ||= '.'
      yield a
    end
  end

  def packages
    ret = []
    TYPES.each do |type|
      next unless File.exist? type
      foreach_record( "#{type}/PATHCONV") do |dir, pack, targ|
        ret.push pack
      end
    end
    ret.uniq
  end

  def foreach_package
    path = {}
    foreach_record do |dir, *rest|
      path[dir] = rest
    end

    base = File.basename( Dir.getwd )
    Dir.foreach('.') do |dir|
      next if dir[0] == ?.
      next unless File.directory? dir

      unless path[dir] then
        raise "abs path for package '#{dir}' not exist"
      end
      pack, targ = path[dir]

      if inclpack( pack, "#{base}/#{dir}" ) then
        chdir( dir ) {
          yield dir, targ
        }
      else
        $stderr.puts "setup.rb: skip #{base}/#{dir}(#{pack}) by user option"
      end
    end
  end

  def inclpack( pack, dname )
    if @with.empty? then
      not @without.include? pack and
      not @without.include? dname
    else
      @with.include? pack or
      @with.include? dname
    end
  end


  def add_rubypath( fn, opt = nil )
    line = "\#!#{@config['ruby-path']}#{opt ? ' ' + opt : ''}"

    $stderr.puts %Q<setting #! line to "#{line}"> if @verbose
    return if @no_harm

    tmpf = nil
    File.open( fn ) do |f|
      first = f.gets
      return unless /\A\#\!.*ruby/ === first

      tmpf = Tempfile.open( 'amsetup' )
      tmpf.puts line
      tmpf << first unless /\A\#\!/o === first
      f.each {|i| tmpf << i }
      tmpf.close
    end
    
    mod = File.stat( fn ).mode
    tmpf.open
    File.open( fn, 'w' ) do |wf|
      tmpf.each {|i| wf << i }
    end
    File.chmod mod, fn

    tmpf.close true
  end


  def install_bin
    install_all isdir(@config['bin-dir']), 0555
  end

  def install_rb( dir )
    install_all isdir(@config['rb-dir'] + '/' + dir), 0644
  end

  def install_dat( dir )
    install_all isdir(@config['data-dir'] + '/' + dir), 0644
  end

  def install_all( dir, mode )
    Dir.foreach('.') do |fname|
      next if /\A\./ === fname
      next unless File.file? fname

      install fname, dir, mode
    end
  end


  def extconf
    system "#{@config['ruby-path']} extconf.rb"
  end

  def make
    command @config['make-prog']
  end
  
  def clean
    command @config['make-prog'] + ' clean'
  end

  def install_so( dir )
    to = isdir(File.expand_path @config['so-dir'] + '/' + dir)
    find_so('.').each do |fn|
      install fn, to, 0555
    end
  end

  def find_so( dir = '.' )
    fnames = nil
    Dir.open( dir ) {|d| fnames = d.to_a }
    exp = /\.#{DLEXT}\z/
    arr = fnames.find_all {|fn| exp === fn }
    unless arr then
      raise InstallError,
        'ruby extention not found: try "ruby setup.rb setup"'
    end

    arr
  end

  def so_dir?( dn = '.' )
    File.file? "#{dn}/MANIFEST"
  end


  ## fileutils

  def isdir( dn )
    mkpath dn
    dn
  end

  def chdir( dn )
    curr = Dir.pwd
    begin
      Dir.chdir dn
      yield
    ensure
      Dir.chdir curr
    end
  end

  def mkpath( dname )
    $stderr.puts "mkdir -p #{dname}" if @verbose
    return if @no_harm

    dirs = dname.split('/')
    if dirs[0].empty? then
      dirs.shift
      path = '/'
    else
      path = ''
    end
    dirs.each do |fname|
      path << fname << '/'
      unless File.directory? path then
        Dir.mkdir path
      end
    end
  end

  def rmf( fname )
    $stderr.puts "rm #{fname}" if @verbose
    return if @no_harm

    File.chmod 777, fname
    File.unlink fname
  end

  def rmrf( dn )
    $stderr.puts "rm -r #{dn}" if @verbose
    return if @no_harm

    Dir.chdir dn
    Dir.foreach('.') do |fn|
      next if fn == '.'
      next if fn == '..'
      if File.directory? fn then
        rmrf fn
      else
        rmf fn
      end
    end
    Dir.chdir '..'
    Dir.rmdir dn
  end

  def install( from, to, mode )
    $stderr.puts "install #{from} #{to}" if @verbose
    return if @no_harm

    if File.directory? to then
      to = to + '/' + File.basename(from)
    end
    str = nil
    File.open( from, 'rb' ) {|f| str = f.read }
    if diff? str, to then
      rmf to if File.exist? to
      File.open( to, 'wb' ) {|f| f.write str }
      File.chmod mode, to
    end
  end

  def diff?( orig, comp )
    return true unless File.exist? comp
    s2 = nil
    File.open( comp, 'rb' ) {|f| s2 = f.read }
    orig != s2
  end

  def command( str )
    $stderr.puts "system #{str}" if @verbose

    unless ret = system( str ) then
      raise RuntimeError, "'system #{str}' failed"
    end
    ret
  end

end


begin
  MainInstaller = Installer.new( ARGV )
  MainInstaller.execute
rescue
  raise if $DEBUG
  $stderr.puts $!
  $stderr.puts 'try "ruby setup.rb --help" for usage'
  exit 1
end
