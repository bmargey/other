package DNASequence;

use Moose;
use POSIX q{floor};
use Readonly;

=pod

=head1 DNASequence

=head2 Description

New object to represent a DNA sequence. Must pass the sequence in the 
constructor.

e.g DNASequence->new({ sequence => <string_sequence> });

=cut

# Moose attribute. Passed in constructor, provides string validation
has 'sequence' => (
	is  => 'ro',
	isa => 'Str',
);

# hash of valid chars and reverse compliments - doesn't change (all upper case
# as spec'd)
Readonly my %RC_RULES => (
	'A' => 'T',
	'T' => 'A',
	'C' => 'G',
	'G' => 'C',
);


=item is_valid

When called on the object, this returns a scalar 1 or 0 (boolean context).

=cut

sub is_valid {
	my $self     = shift;
	my $sequence = $self->sequence;

	foreach my $char (@{ $self->_inflate_sequence($sequence) }) {
		return 0 unless grep { $char eq $_ } keys %RC_RULES;
	}

	return 1;
}


=item reverse_compliment

When called on the object, this validates the sequence and returns a string of
the reverse compliment if valid, or an empty string.

=cut

sub reverse_compliment {
	my $self     = shift;
	my $sequence = $self->sequence;

	# ensure we can process the sequence
	if (!$self->is_valid) {

        # warn in this instance, but would normally write to log file
		warn qq{[EXCP]: Sequence invalid};
		return q{};
	}

	my $compliment = join q{},
		(map { $RC_RULES{$_} } @{ $self->_inflate_sequence($sequence) });

	return reverse $compliment;
}


=item longest_open_reading_frame

Each DNA sequence can have 6 open reading frames. The original has 3 and its
reverse compliment 3 also. This method accepts a flag for the
reverse compliment. If this is passed/evals to true, then the method will
evaluate the reverse compliment. Otherwise, it will evaluate the original
sequence passed in the constructor.

Returns a string or empty string if failure expected.

=cut

sub longest_open_reading_frame {
	my ($self, $reverse) = shift;

	# ensure we can process the sequence
	if (!$self->is_valid) {
		warn qq{[EXCP]: Sequence invalid};
		return q{};
	}

	# set the string to be evaluated based on the flag
	my $string = $reverse ? $self->reverse_compliment : $self->sequence;
	my @sequence = @{ $self->_inflate_sequence($string) };

	# need to split string into strings of 3 chars
	my $range       = scalar @sequence;
	my $split_count = floor($range / 3);

	# create segments of triplets strings by offsetting the start position
	my %segments;
	foreach my $o (0 .. 2) {

		my @segment;
		my $marker = $o;
		for (my $i = 0 ; $i <= $split_count - 1 ; $i++) {

			# add 2 given start is at 0 then splice array
			my $end = $marker + 2;

			# don't bother if beyond scope - it won't be divisible by 3
			last if $end > $range - 1;
			my @splice = @sequence[ $marker .. $end ];

			# add 3 char string into array
			push(@segment, join(q{}, @splice));
			$marker = $end + 1;
		}

		# store the array of strings associated to offset/starting position
		$segments{"offset_$o"} = \@segment;
	}

	# identify the frames
	my %frames;
	foreach my $segmented (keys %segments) {

		my @seg_array = @{ $segments{$segmented} };
		my $length    = scalar @seg_array;
		my ($start, $end);

		# find the start/end codon positions in the segmented array
		foreach my $i (0 .. $length - 1) {
			$start = $i if $seg_array[$i] =~ /ATG/;
			$end   = $i if $seg_array[$i] =~ /TAG|TAA|TGA/;
		}

		# piece together frame string and store in hash with char count
		unless (defined $end && defined $start) {
			print "\t[WARN]: No frame found in sub sequence\n";
			next;
		}

		my @result = @seg_array[ $start .. $end ];
		$frames{ join q{}, @result } = (scalar @result) * 3;

	}

	# bail out gracefully if nothing found
	if (!(keys %frames)) {
		print "\t[WARN]: No frames found in sequence supplied\n";
		return q{};
	}

	# order values and return
	my @ordered = sort { $frames{$b} <=> $frames{$a} } keys %frames;
	return $ordered[0];
}


=item _inflate_sequence

Returns an array ref of chars in a supplied sequence string.

=cut

sub _inflate_sequence {
	my ($self, $string) = @_;
	return [ split //, $string ];
}

no Moose;
1;
