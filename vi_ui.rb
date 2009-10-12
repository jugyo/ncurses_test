# -*- coding: utf-8 -*-
require 'ncurses'
require 'g'

module CommandLine
  # TODO: コマンドラインに入力された文字列をそのまま保持するように変える

  def char_widths
    @char_widths ||= []
    @char_widths
  end

  def position
    y = x = []
    getyx(y, x)
    x.last
  end

  def move_left(i)
    move(0, position - i)
  end

  def move_right(i)
    move(y, position + i)
  end

  def position_in_str
    x = position
    len = 0
    char_widths.each_with_index do |width, index|
      len += width
      return index if len > x
    end
    char_widths.size
  end

  def char_number
    char_widths.size
  end

  def move_to_left_char(i = 1)
    pos_in_str = position_in_str
    return false if pos_in_str <= 1
    x = char_widths[0..(pos_in_str - i - 1)].inject(0) { |width, sum| sum + width }
    move(0, x)
    return true
  end

  def move_to_right_cahr(i = 1)
    pos_in_str = position_in_str
    return false if pos_in_str >= char_number
    x = char_widths[0..(pos_in_str + i - 1)].inject(0) { |width, sum| sum + width }
    move(0, x)
    return true
  end

  def add_char(char)
    x1 = position
    addch(char)
    x2 = position
    width = x2 - x1
    char_widths.insert(position_in_str, width) if width > 0
  end

  def del_char(pos_in_str = nil)
    pos_in_str ||= position_in_str
    width = char_widths.delete_at(pos_in_str)
    if width
      width.times do
        delch
      end
    end
    g char_widths
  end

  def backspace
    if move_to_left_char
      pos_in_str = position_in_str
      del_char(pos_in_str) if pos_in_str > 0
    end
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
          command.move_to_right_cahr
        when Ncurses::KEY_LEFT
          command.move_to_left_char
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
