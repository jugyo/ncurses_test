# -*- coding: utf-8 -*-
require 'ncurses'
require 'g'

module CommandLine
  def self.extended(base)
    base.instance_eval do
      @position = 0
      @text = ''
      @prompt = ':'
    end
  end

  attr_reader :text, :position

  def char_widths
    @char_widths ||= []
    @char_widths
  end

  def clear_text
    @text = ''
    redraw
  end

  def cursor_position
    y = x = []
    getyx(y, x)
    x.last
  end

  def move_left(i = 1)
    return false if @position <= @prompt.size
    @position -= i
    move(0, @position)
  end

  def move_right(i = 1)
    return false if @position >= @text.size
    @position += i
    move(0, @position)
  end

  def add_char(char)
    text << char
    @position += 1
    redraw
  end

  def del_char(pos = nil)
    pos ||= @position
    array = text.split(//)
    array.delete_at(pos)
    @text = array.join
    redraw
  end

  def backspace
    del_char if move_left
  end

  def redraw
    clear
    move(0, 0)
    text.each_byte do |char|
      addch(char)
    end
    move(0, @position)
  end
end

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
  command.extend(CommandLine)
  command.refresh

  list = Ncurses.newwin(lines - 2, cols, 0, 0)
  list.bkgd(Ncurses.COLOR_PAIR(1))
  list.scrollok(true)
  ('a'..'z').each do |i|
    list.addstr(("#{i}" * 100) + "\n")
  end
  list.refresh

  Ncurses.keypad(list, true)
  Ncurses.keypad(command, true)

  loop do
    ch = list.getch
    case ch
    when Ncurses::KEY_DOWN, 'j'[0]
      list.scrl(1)
    when Ncurses::KEY_UP, 'k'[0]
      list.scrl(-1)
    when ':'[0]

      ##################################
      # command mode
      #

      command.move(0, 0)
      command.add_char(':'[0])
      command.move(0, 1)
      command.refresh

      loop do
        cch = command.getch
        case cch
        when Ncurses::KEY_BACKSPACE
          command.backspace
        when 330 # delete
          command.del_char
        when 27 # escape
          break
        when 10 # enter
          break
        when Ncurses::KEY_DOWN
        when Ncurses::KEY_UP
        when Ncurses::KEY_RIGHT
          command.move_right
        when Ncurses::KEY_LEFT
          command.move_left
        else
          command.add_char(cch)
        end
        command.refresh
      end

      command.clear
      command.refresh
    end
    list.refresh
  end
rescue => e
  g "#{e}\n#{e.backtrace.join("\n")}"
ensure
  Ncurses.endwin
end
