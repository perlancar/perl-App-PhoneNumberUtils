package App::PhoneNumberUtils;

use strict;
use warnings;

# AUTHORITY
# DATE
# DIST
# VERSION

our %SPEC;

our %arg0_phnum = (
    phnum => {
        schema => ['str*', match => qr/[0-9]/],
        req => 1,
        pos => 0,
    },
);

our %arg0_phnums = (
    phnums => {
        schema => ['array*', of=>['str*', match => qr/[0-9]/], min_len=>1],
        pos => 0,
        slurpy => 1,
        cmdline_src => 'stdin_or_args',
    },
);

our %argspecopt_strip_whitespace = (
    strip_whitespace => {
        schema => 'bool*',
        cmdline_aliases => {S => {}},
    },
);

$SPEC{phone_number_info} = {
    v => 1.1,
    summary => 'Show information about a phone number',
    description => <<'_',

This utility uses <pm:Number::Phone> to get information for a phone number. For
certain countries, the information provided can be pretty detailed including
coordinate, whether the number is an adult line, and the operator name. For
other countries, the information provided is more basic including whether a
number is a mobile number.

_
    args => {
        %arg0_phnum,
    },
    examples => [
        {args=>{phnum=>'+442087712924'}},
        {args=>{phnum=>'+6281812345678'}},
    ],
};
sub phone_number_info {
    require Number::Phone;

    my %args = @_;

    my $np = Number::Phone->new($args{phnum})
        or return [400, "Invalid phone number '$args{phnum}'"];
    [200, "OK", {
        is_valid => $np->is_valid,
        is_allocated => $np->is_allocated,
        is_in_use => $np->is_in_use,
        is_geographic => $np->is_geographic,
        is_fixed_line => $np->is_fixed_line,
        is_mobile => $np->is_mobile,
        is_pager => $np->is_pager,
        is_ipphone => $np->is_ipphone,
        is_isdn => $np->is_isdn,
        is_adult => $np->is_adult,
        is_personal => $np->is_personal,
        is_corporate => $np->is_corporate,
        is_government => $np->is_government,
        is_international => $np->is_international,
        is_network_service => $np->is_network_service,
        is_drama => $np->is_drama,

        country_code => $np->country_code,
        regulator => $np->regulator,
        areacode => $np->areacode,
        areaname => $np->areaname,
        location => $np->location,
        subscriber => $np->subscriber,
        operator => $np->operator,
        operator_ported => $np->operator_ported,
        #type => $np->type,
        format => $np->format,
        format_for_country => $np->format_for_country,
    }];
}

$SPEC{normalize_phone_number} = {
    v => 1.1,
    summary => 'Normalize phone number',
    description => <<'_',

This utility uses <pm:Number::Phone> to format the phone number, which supports
country-specific formatting rules.

The phone number must be an international phone number (e.g. +6281812345678
instead of 081812345678). But if you specify the `default_country_code` option,
you can supply a local phone number (e.g. 081812345678) and it will be formatted
as international phone number.

This utility can accept multiple numbers from command-line arguments or STDIN.

_
    args => {
        %arg0_phnums,
        default_country_code => {
            schema => 'country::code::alpha2',
        },
        %argspecopt_strip_whitespace,
    },
    examples => [
        {args=>{phnums=>['+442087712924']}},
        {args=>{phnums=>['+6281812345678']}},
    ],
};
sub normalize_phone_number {
    my %args = @_;

    my $mod = "Number::Phone";
    if ($args{default_country_code}) {
        return [400, "Bad syntax for country code, please specify 2-letter ISO country code"]
            unless $args{default_country_code} =~ /\A[A-Za-z]{2}\z/;
        $mod .= "::StubCountry::" . uc($args{default_country_code});
    }

    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;

    my @rows;
    for my $num (@{ $args{phnums} }) {
        my $np = $mod->new($num)
            or return [400, "Invalid phone number '$num'"];
        my $formatted = $np->format;
        if ($args{strip_whitespace}) { $formatted =~ s/\s+//g }
        push @rows, $formatted;
    }

    [200, "OK", @{$args{phnums}} == 1 ? $rows[0] : \@rows];
}

$SPEC{normalize_phone_number_idn} = {
    v => 1.1,
    summary => 'Normalize phone number (for Indonesian number)',
    description => <<'_',

This is a shortcut for:

    % normalize-phone-number --default-country-code id

_
    args => {
        # all args except default_country_code
        %arg0_phnums,
        %argspecopt_strip_whitespace,
    },
    examples => [
        {args=>{phnum=>'+6281812345678'}},
        {args=>{phnum=>'6281812345678'}},
        {args=>{phnum=>'081812345678'}},
    ],
};
sub normalize_phone_number_idn {
    my %args = @_;

    # preprocess
    for (@{ $args{phnums} }) {
        if (/\A62/) { $_ = "+$_" }
    }

    normalize_phone_number(%args, default_country_code=>'id');
}

$SPEC{phone_number_is_valid} = {
    v => 1.1,
    summary => 'Check whether phone number is valid',
    description => <<'_',

This utility uses <pm:Number::Phone> to determine whether a phone number is
valid.

_
    args => {
        %arg0_phnum,
        quiet => {
            schema => 'true*',
            cmdline_aliases => {q=>{}},
        },
    },
    examples => [
        {args=>{phnum=>'+442087712924'}},
        {args=>{phnum=>'+4420877129240'}},
        {args=>{phnum=>'+6281812345678'}},
        {args=>{phnum=>'+6281812345'}},
    ],
};
sub phone_number_is_valid {
    require Number::Phone;

    my %args = @_;

    my $valid = 0;
    {
        my $np = Number::Phone->new($args{phnum}) or last;
        $valid = 1;
    }

    return [200, "OK", $valid, {
        $args{quiet} ? ('cmdline.result' => '') : (),
        'cmdline.exit_code' => $valid ? 0:1,
    }];
}

1;
#ABSTRACT: Utilities related to phone numbers

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

# INSERT_EXECS_LIST


=head1 SEE ALSO

L<Number::Phone>

=cut
