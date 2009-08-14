package Faktro::Types;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.010_000;
use utf8;


# ****************************************************************
# general dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Memoize Protected);
use Carp;


# ****************************************************************
# class variables
# ****************************************************************

our $VERSION = '0.00_00';


# ****************************************************************
# MOP
# ****************************************************************

use Any::Moose;             # automatically turn on strict & warnings
use Any::Moose (
    '::Util::TypeConstraints'       => undef,
);

# メールアドレス
subtype 'Faktro::Types::Common::MailAddress'
    => as 'Faktro::Entity::Common::MailAddress'
;
coerce 'Faktro::Types::Common::MailAddress'
    => from 'Str'
        => via { Faktro::Entity::Common::MailAddress->parse($_) }
;

subtype 'Faktro::Types::Common::MailAddress::Internal'
    => as 'Email::Address'
        => where {
            Faktro::Entity::Common::MailAddress->is_valid_address($_);
        }
        => message { "This email address ($_) is invalid in RFC2821/2822!" }
;
coerce 'Faktro::Types::Common::MailAddress::Internal'
    => from 'Str'
        => via { Faktro::Entity::Common::MailAddress->parse($_) }
;

no Any::Moose;
no Any::Moose (
    '::Util::TypeConstraints'       => undef,
);
__PACKAGE__->meta->make_immutable;


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Faktro::Types - Abstract class for providing original types


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    package MyApp::Entity::Foo;

    use Faktro::Types;

    use Any::Moose;

    is 'mail_address' => (
        is          => 'ro',
        isa         => 'Faktro::Types::Common::MailAddress',
        coerce      => 1,
    );

    no Any::Moose;
    __PACKAGE__->meta->make_immutable;


=head1 DESCRIPTION

blah blah blah

このクラスは、L<Faktro|Faktro>フレームワークに準拠したアプリケーションのMoose/Mouse型を定義している。

各クラスで型を定義した場合の衝突を回避するため、原則的に、型は全てこのクラスに定義されたものか、或いは各アプリケーション固有の型をC<MyApp::Types>に定義したものを使うことがが望ましい。

使用側のクラスでは、このクラスをC<extends>するのではB<なく>、単にC<use>して型をロードすること。


=head1 AUTHOR

=over 4

=item MORIYA Masaki ("Gardejo")

C<< <moriya at ermitejo dot com> >>,
L<http://ttt.ermitejo.com/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009 by MORIYA Masaki ("Gardejo"),
L<http://ttt.ermitejo.com>.

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlapi> and L<perlartistic|perlartistic>.
