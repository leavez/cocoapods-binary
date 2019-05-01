
module UI

    # print log only when verbose
    def verbose_log(message)
        return unless config.verbose?
        UI.puts message
    end
end