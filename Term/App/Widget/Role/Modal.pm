package Term::App::Widget::Role::Modal;

use strict;

use Moose::Role;

has background => (is => 'rw', isa => 'Term::App::Widget', handles => {
  weight         => 'weight',
  preferred_rows => 'preferred_rows',
  preferred_cols => 'preferred_cols',
});

has size       => (is => 'ro', default => 0.75);

sub finish {
  my $self = shift;

  $self->app->child($self->background);
}

around assign_app => sub {
  my ($orig, $self, $app) = @_;

  $self->$orig;

  $self->background->assign_app($app);
};

around render => sub {
  my ($orig, $self) = @_;

  my $rows = $self->rows;
  my $cols = $self->cols;

  $self->background->rows($rows);
  $self->background->cols($cols);

  my @background_lines = @{$self->background->render};

  $self->rows(int($rows * $self->size));
  $self->cols(int($cols * $self->size));

  my @lines = @{$self->$orig()};

  $self->rows($rows);
  $self->cols($cols);

  my $remainder = 1 - $self->size;
  my $start = $rows * ($remainder / 2);

  my $start_col = $cols * ($remainder / 2);
  my $length    = $cols - ($start_col * 2);

  $start     = int($start);
  $start_col = int($start_col);
  $length    = int($length);

  for (my $i = 0; $i < scalar(@lines); $i++) {
    splice(@{$background_lines[$start++]}, $start_col, $length, @{$lines[$i]});
  }

  \@background_lines;
};

no Moose;

1;
