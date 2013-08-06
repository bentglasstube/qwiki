package SimpleWiki::Schema::Result::Page;

use utf8;
use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Core));

__PACKAGE__->table('page');
__PACKAGE__->add_columns(qw(id name title body published views));
__PACKAGE__->set_primary_key('id');

1;
