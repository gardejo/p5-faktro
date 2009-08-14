package Faktro::Entity::Common::MailAddress;


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
use Email::Address;
use Email::Valid::Loose;    # instead of Regexp::Common qw(Email::Address);
use Readonly;
use Scalar::Util qw();
use Storable qw(dclone);


# ****************************************************************
# internal dependencies
# ****************************************************************

use Faktro::Types;


# ****************************************************************
# class constants
# ****************************************************************

# 文字列長（情報源はRFC2821）
Readonly my %Max_Length => (
    total       => 255,
    local_part  =>  64,     # @の前
);


# ****************************************************************
# class variables
# ****************************************************************

our $VERSION = '0.00_00';


# ****************************************************************
# MOP
# ****************************************************************

use Any::Moose;             # automatically turn on strict & warnings

# メールアドレス（委譲先）
has '_mail_address' => (    # 内部使用であることを自己説明する「_」
    is          => 'rw',
    isa         => 'Faktro::Types::Common::MailAddress::Internal',
    required    => 1,
    coerce      => 1,
    handles     => [qw(
        original host user format name as_string
        phrase address comment
    )],
);

around qw(phrase address comment) => \&_validate_and_mutate;

no Any::Moose;
__PACKAGE__->meta->make_immutable;


# ****************************************************************
# operator-overloads
# ****************************************************************

use overload (
    '""'        => 'as_string',
    # 「Magic自動生成」を殺しておかないと、
    # inflate後の比較（ne）がメソッドと勘違いされる。
    # （Data::Model::Schema::Properties::inflate, line 340, ver. 0.00001）
    fallback    => 1,
);


# ****************************************************************
# parts of constructor
# ****************************************************************

# ================================================================
# Purpose    : Moose/Mouseのお口に合うようにnew引数を変換する
# Usage      : 1) Faktro::Entity::Common::MailAddress->new
#            :      ('Foo Bar' => 'foo@bar.example');
#            : 2) Faktro::Entity::Common::MailAddress->new
#            :      (_mail_address => Email::Address->new('foo@bar.example'));
# Parameters : A) Email::Addressと同じ もしくは
#            : B) ( _mail_address => Email::Addressインスタンス )
# Returns    : HashRef[Email::Address]
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub BUILDARGS : Public {
    my ($class, @parameters) = @_;

    return {}
        unless @parameters; # requried違反で死ぬ

    return { @parameters }                                  # parse内ループ由来
        if scalar @parameters == 2
        && $parameters[0] eq '_mail_address'
        && Scalar::Util::blessed $parameters[1];

    return {
        _mail_address => Email::Address->new(@parameters),  # new由来
    };
}

# ================================================================
# Purpose    : インスタンス生成後のバリデーション
# Usage      : $class->new(...);
# Parameters : none
# Returns    : none
# Throws     : no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub BUILD : Public {
    my $self = shift;

    $self->_validate_address;

    return;
}

# ================================================================
# Purpose    : 文字列を解析してメールアドレスオブジェクト（群）を生成して返す
# Usage      : 1) my @addresses = Faktro::Entity::Common::MailAddress->parse
#            :       (q{'foo@bar.example, "Qux Bar" qux@bar.example'});
#            : 2) my @addresses = Faktro::Entity::Common::MailAddress->parse
#            :       (q{"Foo Bar" <foo@bar.example>});
# Parameters : 1-) Email::Address::parseの引数
# Returns    : A) List[Faktro::Entity::Common::MailAddress] もしくは
#            : B) Faktro::Entity::Common::MailAddress
# Throws     : 1) Email::Address::parseでの解析に失敗した場合
#            : 2) Scalarコンテキストなのに複数の結果が生まれる（ような引数
#            :    を与えるというオレオレAPI違反をした）場合
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub parse : Public {
    my $class = shift;

    my @addresses = Email::Address->parse(@_);

    croak "Cannot parse this string ($_) as email address!"
        unless @addresses;                                  # パース失敗

    my @instances;
    foreach my $address (@addresses) {
        push @instances,
            $class->new(_mail_address => $address);         # 生成・検証
    }

    if (wantarray) {
        return @instances;
    }
    else {
        # ArrayRef[Faktro::Entity::Common::MailAddress]にはしない
        croak "Invalid usage: "
            . "called with multiple addresses at SCALAR context"
            if scalar @instances > 1;
        return $instances[0];
    }
}


# ****************************************************************
# hooks for delegations
# ****************************************************************

# ================================================================
# Purpose    : ミューテーターのラッパー
# Usage      : ex.) $self->address('invalid@address');
# Parameters : 2-) 0)のメソッドへの引数（群）
# Returns    : Email::Address
# Throws     : no exceptions
# Comments   : 1) 例外を捕捉した後に処理を続けるならば、変なアドレスが
#            :    _mail_addressに入っていると都合が悪い。一旦Email::Address単独
#            :    で作成しつつ、_mail_addressへのセット時にsubtypeのwhereで
#            :    変な値を（値が入る前に）検知している。
#            : 2) ★中身の_mail_addressのアドレス（refaddr）が変わるが大丈夫？
#            : 3) ★戻り値はEmail::Addressのミューテーターとは違って、
#            :    一律Email::Addressインスタンスとしているが、大丈夫？
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_and_mutate {
    my ($next, $self, @parameters) = @_;

    # アクセッサーがゲッターならお咎め無し
    return $self->$next
        unless @parameters;

    # アクセッサーがセッター（ミューテーター）なら検証する
    my $copy = dclone $self;
    $copy->$next(@parameters);

    return $self->_mail_address($copy->_mail_address);  # subtypeのwhereで検証
}


# ****************************************************************
# validators
# ****************************************************************

# ================================================================
# Purpose    : メールアドレスの検証
# Usage      : try eval { $self->_validate_address }; if (catch my $erro) {...}
# Parameters : none
# Returns    : none
# Throws     : 1) メールアドレスが正しくない（ように見える）場合
# Comments   : 1) ★Faktro::Types::MailAddressのwhere違反messageと被っている。
#            :    例えば$self->_validate_addressではなくて
#            :    $self->_mail_address($self->_mail_address)してはどうか？
# See Also   : n/a
# ----------------------------------------------------------------
sub _validate_address {
    my $self = shift;

    croak "This email address ($_) is invalid in RFC2821/2822!"
        unless $self->is_valid_address;

    return;
}

# ================================================================
# Purpose    : メールアドレスが正しい（ように見える）なら真
# Usage      : 1) if ($self->is_valid_address) {...}
#            : 2) if ($class->is_valid_address($_mail_address)) {...}
# Parameters : Maybe[Email::Address] : $selfの場合は補完している
# Returns    : Bool : 正しい（ように見える）メールアドレスなら真
# Throws     : no exceptions
# Comments   : 1) Regexp::Common::Email::Addressの$RE{Email}{Address}よりも、
#            :    Email::Valid(::Loose)の方が実績があるため、こちらを選択した。
#            : 2) ただ、RFCで規定された文字列長などの確認は追加で行っている。
#            : 3) ★host部の整合性のチェックは、今は省いている。どうだろう。
#            : 4) ★RFC2821/2822を読破した訳ではないので、漏れがまだありそう。
#            : 5) まー、ぶっちゃけバリデーションに血眼になるのもいいけど、
#            :    むしろ確認メールを送って記載URIにアクセスがあったことを以て
#            :    送信成功を判断するのが一番かと……。
# See Also   : n/a
# ----------------------------------------------------------------
sub is_valid_address : Public {
    my ($invocant, $mail_address) = @_;

    $mail_address //= $invocant->_mail_address;

    return Email::Valid::Loose->address($mail_address->address)
        && length($mail_address->address) <= $Max_Length{total}
        && length($mail_address->user   ) <= $Max_Length{local_part}
}

sub mailto : Public {
    return sprintf 'mailto:%s <%s>%s', (
        $_[0]->phrase,
        $_[0]->address,
        (
            $_[0]->comment ? ' (' . $_[0]->comment . ')'
                           : q{}
        ),
    );
}

# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Faktro::Entity::Common::MailAddress - Concrete class of an e-mail address


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    package MyApp::Entity::User;

    use Faktro::Entity::Common::MailAddress;
    use Faktro::Types;

    use Any::Moose;

    has 'mail_address' => (
        is          => 'rw',
        isa         => 'Faktro::Types::Common::MailAddress',
        required    => 1,
    );

    no Any::Moose;
    __PACKAGE__->meta->make_immutable;

    1;


=head1 DESCRIPTION

このモジュールは、L<Faktro|Faktro>フレームワークに於けるメールアドレスを取り扱う具象クラスである。


=head2 データベースへの格納

=head3 inflate

C<parse>をScalarコンテキストで使う。さらに、Moose/Mouse側でBUILDに於いてphrase部を補完しても良い。以下のような形で。

    # 列を跨いだinflate
    sub BUILD {
        my $self = shift;

        $self->mail_address->phrase($self->name);

        return;
    }

=head3 deflate

C<as_string>を使う。……のはやめて、C<address>を使う。

=head3 L<Data::Model|Data::Model>での例

    column_sugar 'user.mail_address'
        => varchar => {
            require     => 1,
            size        => 255,
            inflate     => sub {
                scalar Faktro::Entity::Common::MailAddress->parse($_[0]);
            },
            deflate     => sub {
                $_[0]->address;
            },
        };


=head2 委譲方法の補足

    extends (
        'Email::Address',
        any_moose('::Object'),
    );

して

    no Any::Moose;
    # __PACKAGE__->meta->make_immutable;    # 不可

    sub new {
        my $class = shift;

        my $self = $class->SUPER::new(@_);

        $self->_validate_address;

        return $class->meta->new_object(    # 不可
            __INSTANCE__ => $self,
            # @_,   # 特に他に値はないので
        );
    }

するような継承は、L<Mouse|Mouse>では不可である。C<Mouse::Meta::Class::new_object>が存在しないため。勿論L<Mouse|Mouse>ではクックブックの通り可能である。

従って、素直に委譲する。

=head2 保護

例によって、C<eval>内での問題回避のため、C<Private>やC<Protected>などのPerlアトリビュートは使っていない。どうでもいいけどアトリビュートというのもMoose/MouseのものやらPerl本体のものやらRDBの表に於ける列やら、同音異義語が多くて大変だ。


=head1 SEE ALSO

=over 4

=item 非Moose/Mouseクラスの継承

L<Moose::Cookbook::Basics::Recipe11|Moose::Cookbook::Basics::Recipe11>

=back


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
