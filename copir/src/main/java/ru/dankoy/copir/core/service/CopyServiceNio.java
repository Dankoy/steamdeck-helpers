package ru.dankoy.copir.core.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import ru.dankoy.copir.core.exceptions.FileException;

@Service
public class CopyServiceNio implements CopyService {

  private static final Logger LOG = LoggerFactory.getLogger(CopyServiceNio.class);

  @Override
  public void copyFilesFromTo(String pathFrom, String pathTo) {

    var dirs = listDirsUsingFilesList(pathFrom);
    LOG.debug("Dirs {}", dirs);

    for (Path dir : dirs) {

      var files = listFilesUsingFilesList(dir.toString());

      var filesWithoutHidden = removeHiddenFiles(files);
      LOG.debug("Files {}", filesWithoutHidden);

      for (Path file : filesWithoutHidden) {

        var fileName = file.getFileName().toString();
        var pathToPath = Paths.get(pathTo, fileName);

        if (!Files.exists(pathToPath, LinkOption.NOFOLLOW_LINKS)) {
          try {

            Files.copy(file, pathToPath);
            LOG.info("Copy '{}' to '{}'", file, pathToPath);

          } catch (IOException e) {
            throw new FileException(e);
          }

        } else {
          LOG.info("File '{}' already exists, ignoring.", file);
        }

      }

      copyFilesFromTo(dir.toString(), pathTo);

    }

  }


  private Set<Path> listFilesUsingFilesList(String dir) {
    try (Stream<Path> stream = Files.list(Paths.get(dir))) {
      return stream
          .filter(file -> !Files.isDirectory(file))
          .collect(Collectors.toSet());
    } catch (IOException e) {
      throw new FileException(e);
    }
  }


  private Set<Path> listDirsUsingFilesList(String dir) {
    try (Stream<Path> stream = Files.list(Paths.get(dir))) {
      return stream
          .filter(Files::isDirectory)
          .collect(Collectors.toSet());
    } catch (IOException e) {
      throw new FileException(e);
    }
  }


  private Set<Path> removeHiddenFiles(Set<Path> files) {

    return files.stream()
        .filter(file -> !file.getFileName().toString().startsWith("."))
        .collect(Collectors.toSet());

  }

}
