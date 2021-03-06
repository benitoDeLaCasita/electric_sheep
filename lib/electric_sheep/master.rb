module ElectricSheep
  class Master

    def initialize(options)
      @config = options[:config]
      @logger = options[:logger]
      @workers = [1, options[:workers]].compact.max
      @pidfile=File.expand_path(options[:pidfile]) if options[:pidfile]
    end

    def start!
      raise "Another daemon seems to be running" if running?
      @logger.info "Daemon starting"
      pid=daemonize do
        trap_signals
        while !should_stop? do
          @logger.debug "Searching for scheduled jobs"
          run_scheduled
          flush_workers
          # TODO Configurable rest time
          sleep 1
        end
      end
      write_pidfile(pid)
    end

    def stop!
      @logger.info "Daemon stopping"
      kill_process(read_pidfile)
      File.delete(@pidfile) if File.exists?(@pidfile)
    end

    def restart!
      stop!
      start!
    end

    def running?
      if File.exists?(@pidfile)
        pid = read_pidfile
        return true if process?(pid)
        @logger.warn "Removing pid file #{@pidfile} as the process with pid " +
          "#{pid} does not exist anymore"
        File.delete(@pidfile)
      end
      false
    end

    protected

    def trap_signals
      trap(:TERM){ @should_stop=true }
    end

    def should_stop?
      !!@should_stop
    end

    def write_pidfile(pid)
      @logger.info "Daemon started, pid: #{pid}"
      File.open(@pidfile, 'w') do |f|
        f.puts pid
      end
    end

    def read_pidfile
      File.read(@pidfile).chomp.to_i if File.exists?(@pidfile)
    end

    def kill_process(pid)
      if running?
        @logger.debug "Terminating process #{pid}"
        Process.kill(15, pid)
      end
    end

    def process?(pid)
      pid > 0 && Process.kill(0, pid)
      rescue Errno::ESRCH, RangeError
        false
    end

    def daemonize(&block)
      reader, writer = IO.pipe
      fork_pid=fork do
        Process.daemon
        reader.close
        writer.puts Process.pid
        yield
      end
      # Detach fork to avoid zombie processes
      Process.detach(fork_pid)
      reader.gets.to_i
    end

    def run_scheduled
      @config.iterate do |job|
        if worker_pids.size < @workers
          job.on_schedule do
            # Turn children into daemons to let them run on master stop
            @logger.info "Forking a new worker to handle job " +
              "\"#{job.id}\""
            worker=daemonize do
              Runner::SingleRun.new(@config, @logger, job).run!
            end
            worker_pids[worker]=job.id
            @logger.debug "Forked a worker for job \"#{job.id}\", " +
              "pid: #{worker}"
          end
        end
      end
    end

    def flush_workers
      worker_pids.each do |pid, job|
        unless process?(pid)
          worker_pids.delete(pid)
          @logger.info "Worker for job \"#{job}\" completed, pid: #{pid}"
        end
      end
      @logger.debug "Active workers: #{worker_pids.size}"
    end

    def worker_pids
      @worker_pids||={}
    end

  end
end
