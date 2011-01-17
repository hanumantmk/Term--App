#!/usr/bin/perl -w

use strict;

use Term::App;
use Term::App::Widget::SpreadSheet;
use Term::App::Widget::Text;
use Term::App::Widget::Time;
use Term::App::Widget::Container::LeftToRight;
use Term::App::Widget::Container::TopToBottom;
use Term::App::Event::TailFile;
use Term::App::Event::Timer;
use Term::App::Event::Signal;

my $counter = 1;

my $app = Term::App->new({
  child => Term::App::Widget::Container::TopToBottom->new({
    children => [
      Term::App::Widget::Time->new({
	plugins => ["Centered"],
	weight => 0,
	preferred_rows => 1,
      }),
      Term::App::Widget::Container::LeftToRight->new({
	has_focus => 1,
	children => [
	  Term::App::Widget::Text->new({
	    weight => 0,
	    preferred_cols => 3,
	    text => "\n" . join("\n", 1..9),
	  }),
	  Term::App::Widget::SpreadSheet->new({
	    weight => 2,
	    plugins => ["Paged", "Border"],
	    has_scrollbar => 0,
	    has_focus => 1,
	    bindings => { left_arrow => 'left', right_arrow => 'right', 'down_arrow' => 'down', up_arrow => 'up', page_up => 'page_up', page_down => 'page_down' },
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
	    weight => 1,
	    plugins => ["Centered", "Border"],
	    events => [
	      Term::App::Event::Timer->new({
		seconds => 0.1,
		callback => sub {
		  my $widget = shift;

		  $widget->text($counter++ . "\n" . $widget->rows . "x" . $widget->cols);
		},
	      }),
	    ],
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
    Term::App::Event::Signal->new({
      signal => "WINCH",
      callback => sub {
        my $app = shift;

        $app->draw;
      }
    }),
  ],
});

$app->loop;
