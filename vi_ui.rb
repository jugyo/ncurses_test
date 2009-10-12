# -*- coding: utf-8 -*-
require 'ncurses'
require 'g'

begin
  screen = Ncurses.initscr
  Ncurses.cbreak
  Ncurses.noecho
  Ncurses.start_color
  Ncurses.init_pair(1, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)
  Ncurses.init_pair(2, Ncurses::COLOR_BLACK, Ncurses::COLOR_WHITE)

  lines = Ncurses.LINES
  cols = Ncurses.COLS

  status = Ncurses.newwin(1, cols, lines - 2, 0)
  status.bkgd(Ncurses.COLOR_PAIR(2))
  status.refresh

  command = Ncurses.newwin(1, cols, lines - 1, 0)
  command.refresh

  list = Ncurses.newwin(lines - 2, cols, 0, 0)
  list.bkgd(Ncurses.COLOR_PAIR(1))
  list.scrollok(true)
  ('a'..'z').each do |i|
    list.addstr(("#{i}" * 100) + "\n")
  end
  list.refresh

  Ncurses.keypad(list, true)
  loop do
    ch = list.getch
    case ch
    when Ncurses::KEY_DOWN, 'j'[0]
      list.scrl(1)
    when Ncurses::KEY_UP, 'k'[0]
      list.scrl(-1)
    when ':'[0]
      command.move(0, 0)
      command.addstr(':')
      command.refresh
      buf = ''
      Ncurses.echo
      command.getstr(buf)
      Ncurses.noecho
      command.clear
      command.refresh
      g buf
    end
    list.refresh
  end
rescue => e
  g "#{e}\n#{e.backtrace.join("\n")}"
ensure
  Ncurses.endwin
end
