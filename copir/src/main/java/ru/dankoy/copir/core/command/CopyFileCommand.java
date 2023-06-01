package ru.dankoy.copir.core.command;


import lombok.RequiredArgsConstructor;
import org.springframework.shell.standard.ShellComponent;
import org.springframework.shell.standard.ShellMethod;
import org.springframework.shell.standard.ShellOption;
import ru.dankoy.copir.core.service.CopyService;

@RequiredArgsConstructor
@ShellComponent
public class CopyFileCommand {

  private final CopyService copyService;

  @ShellMethod(key = {"copy",
      "cp"}, value = "Copy all files from multiple nested directories to one flat firectory")
  public String copyFiles(@ShellOption("from") String from, @ShellOption("to") String to) {

    copyService.copyFilesFromTo(from, to);

    return "Done";
  }


}
