(lang dune 3.10)

(name ocaml_playlist_transfer)

(generate_opam_files true)

(source
 (github dmmulroy/ocaml-playlist-transfer))

(authors "Dillon Mulroy")

(maintainers "Dillon Mulroy")

(license MIT)

(documentation https://github.com/dmmulroy/ocaml-playlist-transfer)

(package
 (name ocaml_playlist_transfer)
 (synopsis "Seamlessly transfer playlists between music streaming services")
 (description
  "Seamlessly transfer playlists between music streaming services")
 (depends
  cohttp-lwt-unix
  dune
  jose
  lwt_ssl
  ocaml
  ppx_deriving
  ppx_deriving_yojson
  ptime
  yojson)
 (tags
  (music, ocaml, cli, learning, spotify, apple-music)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
