package Term::App::Widget::Question;

use strict;

use Moose;

use Scalar::Util qw( weaken );

extends 'Term::App::Widget::Container::TopToBottom';

has 'question' => (is => 'ro', isa => 'Str', required => 1);
has 'callback' => (is => 'ro', isa => 'CodeRef', required => 1);
has 'cursor' => (is => 'rw', isa => 'Int');

sub BUILD {
  my $self = shift;

  require Term::App::Widget::Text;

  weaken($self);

  my @children = (
    Term::App::Widget::Text->create({
      preferred_rows => 3,
      text           => "\n" . $self->question . "\n\n",
    }),
    Term::App::Widget::Text->create({
      has_focus => 1,
      preferred_rows => 3,
      plugins => ["Border"],
      bindings => { '' => sub {
	my ($text_widget, $key) = @_;

	if ($key eq "space") {
	  $text_widget->text($text_widget->text . ' ');
	} elsif ($key eq "backspace") {
	  $text_widget->text(substr($text_widget->text, 0, -1));
	} elsif ($key eq "tab") {
	  $text_widget->text($text_widget->text . '  ');
	} elsif ($key eq 'newline') {
	  $self->callback->($text_widget->text);
	} else {
	  $text_widget->text($text_widget->text . $key);
	}
      }},
    }),
  );

  foreach my $child (@children) {
    $child->app($self->app);
    $child->parent($self->parent);
  }

  $self->children(\@children);
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
