module ApplicationHelper
  def package_link(name, platform)
    case platform
    when 'Hex'
      "https://hex.pm/packages/#{name}"
    when 'Dub'
      "http://code.dlang.org/packages/#{name}"
    when 'Emacs'
      "http://melpa.org/#/#{name}"
    when 'Jam'
      "http://jamjs.org/packages/#/details/#{name}"
    end
  end
end
