#!/usr/bin/perl -w

use strict;

use Term::App;
use Term::App::Widget::SpreadSheet;
use Term::App::Widget::Text;
use Term::App::Widget::Container::LeftToRight;
use Term::App::Event::TailFile;
use Term::App::Event::Timer;

my $counter = 1;

my $app = Term::App->new({
  child => Term::App::Widget::Container::LeftToRight->new({
    children => [
      Term::App::Widget::SpreadSheet->new({
	plugins => ["Paged", "Border"],
	has_focus => 1,
	bindings => { left_arrow => 'left', right_arrow => 'right', 'down_arrow' => 'down', up_arrow => 'up' },
	events => [
	  Term::App::Event::TailFile->new({
	    filename => "testfile",
	    callback => sub {
	      my ($widget, $line) = @_;

	      push @{$widget->input}, [split /\t/, $line];
	    },
	  }),
	],
      }),
      Term::App::Widget::Text->new({
	plugins => ["Border"],
	events => [
	  Term::App::Event::Timer->new({
	    seconds => 0.1,
	    callback => sub {
	      my $widget = shift;

	      $widget->text($counter++);
	    },
	  }),
	],
      }),
    ],
  }),
  events => [
    Term::App::Event::Timer->new({
      seconds => 1,
      callback => sub {
        my $app = shift;

        $app->draw;
      }
    }),
  ],
});

$app->loop;
