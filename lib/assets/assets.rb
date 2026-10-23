# frozen_string_literal: true

module Rain
  # Bundles files in the web root into the bundles listed under "assets" in config/config.yaml:
  #
  #   assets:
  #     app.css:
  #       - style.css
  #       - components/*
  #     app.js:
  #       - components/*/*
  #
  # Paths are relative to the web root. A wildcard like "components/*" adds files in alphabetical order 
  # and filters by the bundle's extension. app.css and app.js are exported to the same public folder.
  class Assets
    GLOB_CHARACTERS = /[*?\[{]/

    def initialize(web_root:, bundles:)
      @web_root = File.realpath(web_root)
      @bundles = bundles.to_h { |output, sources| [output.to_s, sources] }
    end

    def build
      @bundles.each_key { |output| write(output) }
    end

    # Rebuilds a bundle whenever one of its files is saved, added or deleted. Runs in the background until the process exits.
    def watch
      require 'listen'

      Listen.to(@web_root) { |modified, added, removed| rebuild(modified + added + removed) }.start
    end

    # Rebuilds only the bundles that include a changed file, so writing a bundle doesn't trigger another rebuild.
    def rebuild(changed_paths)
      changed = changed_paths.map { |path| File.expand_path(path) }

      @bundles.each_key do |output|
        write(output) if changed.any? { |file| source?(output, file) }
      end
    end

    private

    def write(output)
      bundle = sources(output).map { |source| wrap(source, File.read(path(source)), extension: File.extname(output)) }
      File.write(path(output), "#{bundle.join("\n\n")}\n")
    end

    # Each listed path, with wildcards expanded. A file is only included once, and bundles never include themselves.
    def sources(output)
      extension = File.extname(output)
      paths = @bundles[output].flat_map { |source| glob?(source) ? matches(source, extension:) : [source] }

      paths.uniq - @bundles.keys
    end

    def matches(pattern, extension:)
      Dir.glob(pattern, base: @web_root).select { |match| File.extname(match) == extension && File.file?(path(match)) }
    end

    def source?(output, file)
      return false if @bundles.key?(file.delete_prefix("#{@web_root}/"))

      @bundles[output].any? do |source|
        if glob?(source)
          File.extname(file) == File.extname(output) && File.fnmatch?(path(source), file, File::FNM_PATHNAME | File::FNM_EXTGLOB)
        else
          file == path(source)
        end
      end
    end

    def glob?(source)
      source.match?(GLOB_CHARACTERS)
    end

    def wrap(source, content, extension:)
      case extension
      when '.css' then "/* #{source} */\n#{content}"
      # Each script gets its own scope so top-level names can't collide.
      when '.js' then "// #{source}\n(() => {\n#{content}\n})();"
      else content
      end
    end

    def path(relative_path)
      File.join(@web_root, relative_path)
    end
  end
end
