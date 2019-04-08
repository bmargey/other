#!usr/bin perl

use strict;
use warnings;

use Readonly;
use Test::More;

# check class can be loaded
require_ok 'DNASequence';

Readonly my %mock_sequences => (
	valid                    => 'ACAAGAATGTGGTAA',
	valid_reverse_compliment => 'TTACCACATTCTTGT',
	longest_og_orf           => 'ATGTGGTAA',
	invalid                  => 'ABCDEFGHIJJKMNOPQRSTUVWXYZ',
);

# check class can be instantiated and object created
can_ok 'DNASequence', 'new';
my $valid_obj   = DNASequence->new({ sequence => $mock_sequences{valid} });
my $invalid_obj = DNASequence->new({ sequence => $mock_sequences{invalid} });

is $valid_obj->sequence, $mock_sequences{valid}, 'Object created with sequence';

subtest 'Method testing' => sub {

    # _inflate_sequence
	can_ok 'DNASequence', '_inflate_sequence';
	is_deeply $valid_obj->_inflate_sequence('ABC'), [qw{A B C}],
		'String sequence converted to array as expected';
	is_deeply $valid_obj->_inflate_sequence(''), [],
		'Empty string results in empty array';
    
    # is_valid
	can_ok 'DNASequence', 'is_valid';
	is $valid_obj->is_valid,   1, 'Valid string returns true';
	is $invalid_obj->is_valid, 0, 'Invalid string returns false';

    # reverse_compliment
	can_ok 'DNASequence', 'reverse_compliment';
	is $valid_obj->reverse_compliment,
		$mock_sequences{valid_reverse_compliment},
		'Reverse compliment as expected';
	is $invalid_obj->reverse_compliment, q{},
		'Invalid sequence returns empty string';

    # longest_open_reading_frame
	can_ok 'DNASequence', 'longest_open_reading_frame';
	is $valid_obj->longest_open_reading_frame, $mock_sequences{longest_og_orf},
		'Longest open reading frame returned as expected';
	is $invalid_obj->longest_open_reading_frame, q{},
		'Invalid sequence returns empty string';
};

done_testing;
