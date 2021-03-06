class Pod::Perl5::ToHTML
{

  # we default to stdout
  has $.output_filehandle = $*OUT;

  # this maps pod encoding values to their HTML equivalent
  # if no mapping is found, the pod encoding value will be
  # used
  has %.encoding_map = utf8 => 'UTF-8';

  # %html is where the converted markup is added
  has %!html = head => '', body => '';

  # when we're in a list, we buffer paragraph content
  # this FIFO stack records whether we're in a list and the list type
  # a stack is useful for nested lists!
  has @!list_stack = Array.new();

  method add_to_html (Str:D $section_name, Str:D $string)
  {
    die "Section $section_name doesn't exist!" unless %!html{$section_name}:exists;
    %!html{$section_name} ~= $string;
  }

  # buffer is used as a temporary store when formatting needs to
  # be nested, e.g.: <p><i>some text</i></p>
  # the italicised text is stored in the paragraph buffer
  # and when the paragraph() executes, it replaces its
  # contents with the buffer
  has %!buffer = paragraph => Array.new(), _item => Array.new();

  method get_buffer (Str:D $buffer_name) is rw
  {
    die ("buffer {$buffer_name} does not exist!") unless %!buffer{$buffer_name}:exists;
    return-rw %!buffer{$buffer_name}; # return-rw required, a naked "return" forces ro
  }

  method add_to_buffer (Str:D $buffer_name, Pair:D $pair)
  {
    self.get_buffer($buffer_name).push($pair);
  }

  method clear_buffer (Str:D $buffer_name)
  {
    self.get_buffer($buffer_name) = Array.new();
  }

  # once parsing is complete, this method is executed
  # we format and print the $html
  method TOP ($/ is copy) # required as regex writes to $/, and $/ is read only by default
  {
    say qq:to/END/;
      <html>
      { if my $head = %!html<head> { "<head>\n{$head}</head>" } }
      { if my $body = %!html<body>
        {
          # remove redundant pre tags
          "<body>\n{$body.subst(/\<\/pre\>\s*\<pre\>/, {''}, :g)}</body>"
        }
      }
      </html>
      END
  }

  method head1 ($/)
  {
    self.add_to_html('body', "<h1>{$/<singleline_text>.Str}</h1>\n");
  }

  method head2 ($/)
  {
    self.add_to_html('body', "<h2>{$/<singleline_text>.Str}</h2>\n");
  }

  method head3 ($/)
  {
    self.add_to_html('body', "<h3>{$/<singleline_text>.Str}</h3>\n");
  }

  method head4 ($/)
  {
    self.add_to_html('body', "<h4>{$/<singleline_text>.Str}</h4>\n");
  }

  method paragraph ($/ is copy) # required as regex writes to $/, and $/ is read only by default
  {
    my $original_text = $/<text>.Str.chomp;
    my $para_text = $/<text>.Str.chomp;

    for self.get_buffer('paragraph').reverse -> $pair # reverse as we're working outside in, replacing all formatting strings with their HTML
    {
      $para_text = $para_text.subst($pair.key, {$pair.value});
    }

    # buffer the text if we're in a list
    if @!list_stack.elems > 0
    {
      self.add_to_buffer('_item', $original_text => "<p>{$para_text}</p>");
    }
    else
    {
      self.add_to_html('body', "<p>{$para_text}</p>\n");
    }
    self.clear_buffer('paragraph');
  }

  method verbatim_paragraph ($/)
  {
    self.add_to_html('body', "<pre>{$/.Str}</pre>\n");
  }

  method begin_end ($/ is copy) # required as regex writes to $/, and $/ is read only by default
  {
    # make a copy so the regex can clobber $/
    my $begin_end = $/;
 
    if $/<begin><name>.Str.match(/^ HTML $/, :i)
    {
      self.add_to_html('body', "{$begin_end<begin_end_content>.Str}\n");
    }
  }

  method _for ($/ is copy) # required as regex writes to $/, and $/ is read only by default
  {
    # make a copy so the regex can clobber $/
    my $for = $/;

    if $/<name>.Str.match(/^ HTML $/, :i)
    {
      self.add_to_html('body', "{$for<singleline_text>.Str}\n");
    }
  }

  method encoding ($/)
  {
    my $encoding = $/<name>.Str;

    if %.encoding_map{$encoding}:exists
    {
      $encoding = %.encoding_map{$encoding};
    }
    self.add_to_html('head', qq{<meta charset="$encoding">\n});
  }


  # formatting codes are added to a buffer which is used to replace
  # text in the parent paragraph
  proto method format_codes { * }

  multi method format_codes:italic ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "<i>{$/<multiline_text>.Str}</i>");
  }

  multi method format_codes:bold ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "<b>{$/<multiline_text>.Str}</b>");
  }

  multi method format_codes:code ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "<code>{$/<multiline_text>.Str}</code>");
  }

  multi method format_codes:escape ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "&{$/<singleline_format_text>.Str};");
  }

  # spec says to display in italics
  multi method format_codes:filename ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "<i>{$/<singleline_format_text>.Str}</i>");
  }

  # singleline shouldn't break across lines, use <pre> to preserve the layout
  multi method format_codes:singleline ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "<pre>{$/<singleline_format_text>.Str}</pre>");
  }

  # ignore index and zeroeffect
  multi method format_codes:index ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "");
  }
  multi method format_codes:zeroeffect ($/)
  {
    self.add_to_buffer('paragraph', $/.Str => "");
  }

  multi method format_codes:link ($/ is copy) # required as regex writes to $/, and $/ is read only by default
  {
    my $original_string = $/.Str;
    my ($url, $text) = ("","");

    if $/<url>:exists and $/<singleline_format_text>:exists
    {
      $text = $/<singleline_format_text>.Str;
      $url  = $/<url>.Str;
    }
    elsif $/<url>:exists
    {
      $text = $/<url>.Str;
      $url  = $/<url>.Str;
    }
    elsif $/<singleline_format_text>:exists and $/<name>:exists and $/<section>:exists
    {
      $text = $/<singleline_format_text>.Str;
      $url  = "http://perldoc.perl.org/{$/<name>.Str}.html#{$/<section>.Str}";
    }
    elsif $/<name>:exists and $/<section>:exists
    {
      $text = "{$/<name>.Str}#{$<section>.Str}";
      $url  = "http://perldoc.perl.org/{$/<name>.Str}.html#{$/<section>.Str}";
    }
    elsif $/<name>:exists
    {
      $text = $/<name>.Str;
      $url  = "http://perldoc.perl.org/{$/<name>.Str}.html";
    }
    else #must just be a section on current doc
    {
      $text = $<section>.Str;
      $url  = "#{$/<section>.Str}";
    }

    # replace "::" with slash for the perldoc URLs
    if $url ~~ m/^https?\:\/\/perldoc\.perl\.org/
    {
      $url = $url.subst('::', {'/'}, :g);
    }
    self.add_to_buffer('paragraph', $original_string => qq|<a href="{$url}">{$text}</a>|);
  }

  # ignoring ol
  method over ($/)
  {
    # assume it's an unordered list
    my $list_type = 'ul';

    # the stack is a FIFO store which remembers if we're in a list, and what type
    @!list_stack.push($list_type);
    self.add_to_html('body', "<{$list_type}>\n");
  }

  method _item ($/)
  {
    my $item_text = self.get_buffer('_item').map({.value}).join('\n');
    self.add_to_html('body', "<li>\n{$item_text}\n</li>\n");
    self.clear_buffer('_item');
  }

  method back ($/)
  {
    my $list_type = @!list_stack.pop;
    self.add_to_html('body', "</{$list_type}>\n");
  }
}

=begin pod

=head1 WARNING

This class is in development and subject to change

=head1 NAME

Pod::Perl5::ToHTML - an action class for C<Pod::Perl5::Grammar>, for converting pod to HTML

=head1 SYNOPSIS

  use Pod::Perl5::Grammar;
  use Pod::Perl5::ToHTML;

  # parse some pod to html
  my $to_html_action = Pod::Perl5::ToHTML.new;
  Pod::Perl5::Grammar.parse($some_pod_string, :actions($to_html_action));

=head1 METHODS

=head2 new (output_filehandle => $filehandle)

Creates a new C<Pod::Perl5::ToHTML> object. Optionally can take a filehandle argument, else
defaults to stdout

=cut

=end pod
