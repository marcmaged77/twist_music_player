/// How the lane's header and cards are drawn.
enum TwistSwimlaneStyle {
  /// Logo, title and a promo chip on the host's background.
  plain,

  /// A gradient band with the logo, title, offer text and a download pill;
  /// the cards overlap the band's bottom edge.
  banner,

  /// A flat-bottomed gradient band with the wordmark and a "Download Now"
  /// pill on one line, the lane title in caps and the offer under it, then a
  /// fan of tiles: the centre one upright on top, the neighbours tucked under
  /// it, smaller, tilted and dimmed, each with its title and artist underneath.
  coverflow,
}
