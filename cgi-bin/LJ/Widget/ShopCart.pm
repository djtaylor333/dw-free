#!/usr/bin/perl
#
# LJ::Widget::ShopCart
#
# Returns the current shopping cart for the remote user.
#
# Authors:
#      Janine Costanzo <janine@netrophic.com>
#
# Copyright (c) 2009 by Dreamwidth Studios, LLC.
#
# This program is free software; you may redistribute it and/or modify it under
# the same terms as Perl itself.  For a copy of the license, please reference
# 'perldoc perlartistic' or 'perldoc perlgpl'.
#

package LJ::Widget::ShopCart;

use strict;
use base qw/ LJ::Widget /;
use Carp qw/ croak /;

sub need_res { qw( stc/shop.css ) }

sub render_body {
    my ( $class, %opts ) = @_;

    my $ret;

    my $cart = DW::Shop->get->cart
        or return $class->ml( 'widget.shopcart.error.nocart' );

    return $class->ml( 'widget.shopcart.error.noitems' )
        unless @{$cart->items};

    $ret .= $class->start_form;

    $ret .= "<table class='shop-cart'>";
    $ret .= "<tr><th>" . $class->ml( 'widget.shopcart.header.remove' ) . "</th>";
    $ret .= "<th>" . $class->ml( 'widget.shopcart.header.item' ) . "</th>";
    $ret .= "<th>" . $class->ml( 'widget.shopcart.header.deliverydate' ) . "</th>";
    $ret .= "<th>" . $class->ml( 'widget.shopcart.header.to' ) . "</th>";
    $ret .= "<th>" . $class->ml( 'widget.shopcart.header.from' ) . "</th>";
    $ret .= "<th>" . $class->ml( 'widget.shopcart.header.price' ) . "</th></tr>";
    foreach my $item ( @{$cart->items} ) {
        my $from_u = LJ::load_userid( $item->from_userid );

        $ret .= "<tr>";
        $ret .= "<td>" . $class->html_check( name => 'remove_' . $item->id, value => 1 ) . "</td>";
        $ret .= "<td>" . $item->name_html . "</td>";
        $ret .= "<td>" . ( $item->deliverydate ? $item->deliverydate : $class->ml( 'widget.shopcart.deliverydate.today' ) ) . "</td>";
        $ret .= "<td>" . $item->t_html . "</td>";
        $ret .= "<td>" . ( $item->anonymous || !LJ::isu( $from_u ) ? $class->ml( 'widget.shopcart.anonymous' ) : $from_u->ljuser_display ) . "</td>";
        $ret .= "<td>\$" . $item->cost . " USD</td>";
        $ret .= "</tr>";
    }
    $ret .= "<tr><td colspan='6' class='total'>" . $class->ml( 'widget.shopcart.total' ) . " \$" . $cart->display_total . " USD</td></tr>";
    $ret .= "</table>";

    $ret .= "<div class='shop-cart-btn'>";

    $ret .= "<p>" . $class->html_submit( removeselected => $class->ml( 'widget.shopcart.btn.removeselected' ) ) . " ";
    $ret .= $class->html_submit( discard => $class->ml( 'widget.shopcart.btn.discard' ) ) . "</p>";

    my @paypal_option = ( paypal => $class->ml( 'widget.shopcart.paymentmethod.paypal' ) )
        if keys %LJ::PAYPAL_CONFIG;
    $ret .= "<p>" . $class->ml( 'widget.shopcart.paymentmethod' ) . " ";
    $ret .= $class->html_select(
        name => 'paymentmethod',
        selected => keys %LJ::PAYPAL_CONFIG ? 'paypal' : 'checkmoneyorder',
        list => [
            @paypal_option,
            checkmoneyorder => $class->ml( 'widget.shopcart.paymentmethod.checkmoneyorder' ),
        ],
    ) . " ";
    $ret .= $class->html_submit( checkout => $class->ml( 'widget.shopcart.btn.checkout' ) ) . "</p>";

    $ret .= "</div>";

    $ret .= $class->end_form;

    return $ret;
}

sub handle_post {
    my ( $class, $post, %opts ) = @_;

    # check out
    if ( $post->{checkout} ) {
        my $method = 'paypal';
        $method = 'checkmoneyorder' if $post->{paymentmethod} eq 'checkmoneyorder' || !keys %LJ::PAYPAL_CONFIG;

        return BML::redirect( "$LJ::SITEROOT/shop/checkout?method=$method" );
    }

    # remove selected items
    if ( $post->{removeselected} ) {
        my $cart = DW::Shop->get->cart
            or return ( error => $class->ml( 'widget.shopcart.error.nocart' ) );

        foreach my $val ( keys %$post ) {
            next unless $post->{$val} && $val =~ /^remove_(\d+)$/;
            $cart->remove_item( $1 );
        }
    }

    # discard entire cart
    if ( $post->{discard} ) {
        return BML::redirect( "$LJ::SITEROOT/shop?newcart=1" );
    }

    return;
}

1;
