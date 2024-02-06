module Papercrop
  module Helpers

    # Form helper to render the cropping preview box of an attachment.
    # Box width can be handled by setting the :width option.
    # Width is 100 by default. Height is calculated by the aspect ratio.
    #
    #   crop_preview :avatar
    #   crop_preview :avatar, :width => 150
    #
    # @param attachment [Symbol] attachment name
    # @param opts [Hash]
    def crop_preview(attachment, opts = {})
      attachment = attachment.to_sym
      width      = opts[:width] || 100
      height     = (width / self.object.send(:"#{attachment}_aspect")).round
      signed     = opts[:signed]
      time       = opts[:time] || 3600

      if self.object.send(attachment).class == Paperclip::Attachment
        wrapper_options = {
          :id    => "#{attachment}_crop_preview_wrapper",
          :style => "width:#{width}px; height:#{height}px; overflow:hidden"
        }

        image_options = {
          :id    => "#{attachment}_crop_preview",
          :style => "max-width:none; max-height:none"
        }

        preview_image =
          if signed
            @template.image_tag(self.object.send(attachment).expiring_url(time), image_options)
          else
            @template.image_tag(self.object.send(attachment).url, image_options)
          end

        @template.content_tag(:div, preview_image, wrapper_options)
      end
    end


    # Form helper to render the main cropping box of an attachment.
    # Loads the original image. Initially the cropbox has no limits on dimensions, showing the image at full size.
    # You can restrict it by setting the :width option to the width you want.
    #
    #   cropbox :avatar, :width => 650
    #
    # Also, you can use some of the options jcrop has in its api for extra customization.
    # @see http://deepliquid.com/content/Jcrop_Manual.html
    # :width and :aspect are aliases for :box_width and :aspect_ratio respectively
    #
    #   cropbox :avatar, :box_width => 650, :aspect_ratio => 1, :set_select => [0, 0, 500, 500]
    #
    # Keep in mind that calling the cropbox with an empty or not persisted attachment will result into an empty div
    #
    # @param attachment [Symbol] attachment name
    # @param opts [Hash] @see Papercrop::Cropbox for more info
    def cropbox(attachment, opts = {})
      cropbox = Papercrop::Cropbox.new(object, attachment)

      if cropbox.image_is_present?
        box  = hidden_field(:"#{attachment}_original_w", :value => cropbox.original_width)
        box << hidden_field(:"#{attachment}_original_h", :value => cropbox.original_height)

        for attribute in [:crop_x, :crop_y, :crop_w, :crop_h] do
          box << hidden_field(:"#{attachment}_#{attribute}", :id => "#{attachment}_#{attribute}")
        end

        crop_image = @template.image_tag(self.object.send(attachment).url)
        jcrop_opts = cropbox.parse_jcrop_opts(opts)

        box << @template.content_tag(:div, crop_image, :id => "#{attachment}_cropbox", :data => jcrop_opts)
      else
        @template.content_tag(:div, "", :id => "#{attachment}_cropbox_blank")
      end
    end
  end
end


if defined? ActionView::Helpers::FormBuilder
  ActionView::Helpers::FormBuilder.class_eval do
    include Papercrop::Helpers
  end
end
