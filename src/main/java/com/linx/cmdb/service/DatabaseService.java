package com.linx.cmdb.service;

import com.linx.cmdb.entity.Command;
import com.linx.cmdb.repository.CommandRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DatabaseService {

    private final CommandRepository commandRepository;

    public String getCommand(Long id) {
        return commandRepository.findById(id).map(Command::getCommand).orElse(null);
    }

    public void deleteCommand(Long id) {
        commandRepository.deleteById(id);
    }

    public void createCommand(String label, String command) {
        Command newCommand = Command.builder()
                .label(label)
                .command(command)
                .createdAt(System.currentTimeMillis())
                .build();
        commandRepository.save(newCommand);
    }

    public String searchCommand(String label) {
        return commandRepository.findByLabelContainingIgnoreCase(label).stream()
                .map(Command::getCommand)
                .findFirst()
                .orElse(null);
    }

}
