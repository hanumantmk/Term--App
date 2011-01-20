#!/usr/bin/perl -w

use strict;

use Term::App;
use Term::App::Widget::SpreadSheet;
use Term::App::Widget::Text;
use Term::App::Widget::Time;
use Term::App::Widget::Container::LeftToRight;
use Term::App::Widget::Container::TopToBottom;
use Term::App::Widget::Histogram;
use Term::App::Event::TailFile;
use Term::App::Event::Timer;
use Term::App::Event::Signal;
use Term::App::Event::WatchFile;
use Term::App::Data::Numbers;
use Term::App::Data::Numbers::Weighted;

my $counter = 1;

my ($spreadsheet, $text);

my $app = Term::App->new({
  child => Term::App::Widget::Container::TopToBottom->new({
    bindings => {
      tab => sub {
	my $self = shift;

	$self->toggle_focus($spreadsheet, $text);
      }
    },
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
	  Term::App::Widget::Container::TopToBottom->new({
	    weight => 1,
	    children => [
	      Term::App::Widget::Histogram->new({
		plugins => ["Border"],
		data => Term::App::Data::Numbers->new,
		events  => [
		  Term::App::Event::Timer->new({
		    seconds  => 1,
		    callback => sub {
		      my $widget = shift;

		      $widget->data->integrate(map { int(rand(6)) + int(rand(6)) } (1..10)),
		    },
		  }),
		],
	      }),
	      Term::App::Widget::Histogram->new({
		plugins => ["Border"],
		orientation => 'vertical',
		data => Term::App::Data::Numbers::Weighted->new({
		  high => 30,
		}),
		events  => [
		  Term::App::Event::Timer->new({
		    seconds  => 1,
		    callback => sub {
		      my $widget = shift;

		      $widget->data->integrate(map { int(rand(20)) + int(rand(20)) } (1..1000)),
		    },
		  }),
		],
	      }),
	    ],
	  }),
	  ($spreadsheet = Term::App::Widget::SpreadSheet->new({
	    weight => 2,
	    plugins => ["Paged", "Border"],
	    has_focus => 1,
	    bindings => { '/' => 'start_search', left_arrow => 'left', right_arrow => 'right', 'down_arrow' => 'down', up_arrow => 'up', page_up => 'page_up', page_down => 'page_down', home => 'home', end => 'end' },
	    events => [
	      Term::App::Event::TailFile->new({
		filename => "testfile",
		callback => sub {
		  my ($widget, $line) = @_;

		  push @{$widget->input}, [split /\t/, $line];
		},
	      }),
	    ],
	  })),
	  Term::App::Widget::Container::TopToBottom->new({
	    weight => 1,
	    has_focus => 1,
	    children => [
	      ($text = Term::App::Widget::Text->new({
		plugins => ["Paged", "Border"],
		bindings => { left_arrow => 'left', right_arrow => 'right', 'down_arrow' => 'down', up_arrow => 'up', page_up => 'page_up', page_down => 'page_down', home => 'home', end => 'end' },
		has_scrollbar => 0,
		events => [
		  Term::App::Event::WatchFile->new({
		    filename => 'testfile',
		    initial_read => 1,
		    callback => sub {
		      my ($widget, $content) = @_;

		      $widget->text($content);
		    },
		  }),
	        ],
	      })),
	      Term::App::Widget::Text->new({
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
