#!/usr/bin/perl -w

use strict;

use Term::App;
use Term::App::Widget::Text;

my $app = Term::App->new({
  child => Term::App::Widget::Text->new({
    text => "foo\nbar\nbaz\n",
    plugins => ["Paged", "Border"],
    bindings => { left_arrow => 'left', right_arrow => 'right', 'down_arrow' => 'down', up_arrow => 'up' },
  }),
});

$app->loop;
