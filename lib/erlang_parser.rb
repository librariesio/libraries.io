# from https://github.com/allenhwkim/erl_to_ruby/blob/ada08e22c39bf6cc7204102a7eb83121b65a051f/erl_to_ruby.rb
class ErlangParser
  CLOSE_STRS  = {"["=>"]", "{"=>"}", '"'=>'"', "'"=>"'", '<<'=>'>>', "#Ref<"=>">", "<"=>">"}

  def self.erl_term(str)
    str.strip!
    term_open_str = str[/^(\[|\{|\"|\'|<<|#Ref|<)/,1]
    if term_open_str.nil? # integer,float, or, atom
      matches = /^(([-0-9\.]+)|([a-z][a-z0-9_]*))/.match(str)
      term = case
        when (matches[2] && str[/\./]) then str.to_f
        when matches[2] then str.to_i
        when matches[3] then str.to_sym
      end
    else
      term_close_str = CLOSE_STRS[term_open_str]
      re_ends_with_close_str = Regexp.new(Regexp.escape("#{term_close_str}")+"$")
      raise "Parse error, Invalid erlang term #{str}" unless re_ends_with_close_str.match(str)
      term = case term_open_str
        when '[' then ErlList.new(str)
        when '{' then ErlTuple.new(str)
        when '"' then ErlString.new(str)
        when "'" then ErlAtom.new(str)
        when "<<" then ErlBinary.new(str)
        when "#Ref" then ErlRef.new(str)
        when "<" then ErlPid.new(str)
        else raise "Parse error with #{term_open_str}"
      end
    end
    term
  end



  class ErlTerm
    attr_accessor :str
    def initialize(str)
      @str = str
    end
  end

  class ErlEnumeration
    attr_accessor :str, :elements
    def initialize(str)
      @str = str
      @elements = []
    end

    def parse
      strs = get_element_strs
      @elements = parse_element_strs(strs)
    end

    def pos_close_str(str, open_str)
      close_str = CLOSE_STRS[open_str]
      if open_str == close_str
        return str.index(close_str,1)
      else
        open_count = 1
        for i in ((str.index(open_str)+1)..(str.length))
          opened = (str[i,open_str.length ] == open_str)
          open_count += 1 if opened
          closed = (str[i,close_str.length] == close_str)
          open_count -= 1 if closed
          return i if (closed && open_count==0)
        end
        raise "Parse error, not found matching close of #{open_str} in #{str}"
      end
    end

    def parse_first_term(str_to_parse)
      open_str = str_to_parse[/^(\[|\{|\"|\'|<<|#Ref|<)/,1]
      if open_str
        close_str = CLOSE_STRS[open_str]
        pos_open_str = str_to_parse.index(open_str)
        pos_close_str = pos_close_str(str_to_parse,open_str)
        term_str = str_to_parse[pos_open_str..(pos_close_str+close_str.length-1)]
        new_str_to_parse = str_to_parse[(pos_close_str+close_str.length), str.length]
      else
        pos_open_str = 0
        pos_close_str = str_to_parse.index(",") || str_to_parse.length
        term_str = str_to_parse[pos_open_str..(pos_close_str-1)]
        new_str_to_parse = str_to_parse[pos_close_str+1, str.length]
      end
      new_str_to_parse = "" if new_str_to_parse.nil?
      [term_str, new_str_to_parse.gsub(/^[,\s]+/,"")]
    end

    #parse @str to elements to the end of @str, and each elements must be separated by ","
    def get_element_strs
      element_strs=[]
      str_to_parse = @str[1,@str.length-2].strip  # between [ and ], or { and }
      until str_to_parse == ""
        term_str, new_str_to_parse = parse_first_term(str_to_parse)
        element_strs << term_str
        str_to_parse = new_str_to_parse
      end
      element_strs
    end

    def parse_element_strs(strs)
      strs.map {|term_str|
        term = ErlangParser.erl_term(term_str)
        if term.is_a?(ErlTuple) or term.is_a?(ErlList)
          term_strs = term.get_element_strs
          term.elements = term.parse_element_strs(term_strs)
        end
        term
      }
    end

  end

  class ErlAtom < ErlTerm
    def to_ruby
      self.str.gsub(/'/,"")
    end
  end

  class ErlBinary < ErlTerm
    def to_ruby
      self.str.gsub!(/[<>]/,"")
      bin_els = self.str.split(",")
      els = bin_els.map { |el|
        if el[/^[0-9]+$/]
          el.to_i
        elsif el[/^"/]
          el.gsub(/"/,"")
        end
      }
      els.length > 1 ? els : els[0]
    end
  end

  class ErlPid < ErlTerm
    def to_ruby
      self.str.gsub!(/<>/,"")
      bin_els = self.str.split(".")
    end
  end

  class ErlRef < ErlTerm
    def to_ruby
      self.str.gsub!(/#Ref<|>/,"")
      bin_els = self.str.split(".")
    end
  end

  class ErlString < ErlTerm
    def to_ruby
      self.str.gsub(/"/,"")
    end
  end

  class ErlList < ErlEnumeration
    def to_ruby
      @elements.map {|el|
        (el.is_a?(ErlTerm) || el.is_a?(ErlEnumeration))? el.to_ruby : el
      }
    end
  end

  class ErlTuple < ErlEnumeration
    def to_ruby
      arr = @elements.map {|el|
        (el.is_a?(ErlTerm) || el.is_a?(ErlEnumeration))? el.to_ruby : el
      }
      key = arr.delete_at(0)
      hash = {key => ( arr.length>1 ? arr: arr[0])}
    end
  end

  def erl_to_ruby(str)
  str.gsub!(/[\n\r]/,"")
    erl_obj = ErlangParser.erl_term(str)
    erl_obj.parse if erl_obj.is_a?(ErlEnumeration)
    erl_obj.to_ruby
  end

  #
  #example
  #
  #pp erl_to_ruby("[{a,[{a_foo,'ABCDE',\"ABCDE\",<<\"ABCDE\">>},{a_bar,1,2,3}]},{b,[{b_foo,1,2,3},{b_bar,1,2,3}]}]")
  #pp erl_to_ruby(" {a,[{a_foo,'ABCDE',\"ABCDE\",<<\"ABCDE\">>}]} ")
  #pp erl_to_ruby("   <<12,13,14,15,16,17,18,\"abcdefg\">> ")
  #pp erl_to_ruby("{true,<<\"o_e-13885-2\">>,expiry,          {63487411200,63519123599,[{offer,9434},{offer_url,none}]}}")
  #pp erl_to_ruby( "[{sub,<<\"JCT\">>}, {sub2,none}]")
end
