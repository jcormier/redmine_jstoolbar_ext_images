# Allow {{thumbnail}} macros to render in the live preview tab.
#
# Wrapped in a module (matching the file name) so it is compatible with
# Rails 7.2 / Zeitwerk eager loading on Redmine 6. The actual patching is
# performed by .apply!, invoked from the plugin initializer inside a
# to_prepare block.
module WikiFormattingMacrosPatch
  # Lightweight stand-in object so the thumbnail macro can resolve
  # attachments while rendering the preview tab (where no persisted
  # container object is available yet).
  class RedmineEditorPreviewTabThumbnail
    attr_reader :attachments

    def initialize(attachments)
      @attachments = attachments
    end
  end

  def self.apply!
    definitions = Redmine::WikiFormatting::Macros::Definitions
    unless definitions.method_defined?(:macro_original_thumbnail)
      definitions.send(:alias_method, :macro_original_thumbnail, :macro_thumbnail)
    end

    Redmine::WikiFormatting::Macros.class_eval do
      macro :thumbnail do |obj, args|
        adjusted_args = args.dup
        adjusted_args[0] = URI::DEFAULT_PARSER.unescape(args[0]) if args[0]
        obj ||= WikiFormattingMacrosPatch::RedmineEditorPreviewTabThumbnail.new(@attachments) if @attachments
        macro_original_thumbnail(obj, adjusted_args)
      end
    end
  end
end
