package com.linx.cmdb.controller;

import com.linx.cmdb.service.DatabaseService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RequiredArgsConstructor
@RestController
@RequestMapping("/api")
public class CommandController {

    private final DatabaseService databaseService;

    @GetMapping("/commands")
    public ResponseEntity<Map<String, String>> getCommands(){
        return ResponseEntity.ok(Map.of("message", ""));
    }

    @GetMapping("/commands/search")
    public ResponseEntity<Map<String, String>> searchCommand(String label){
        return ResponseEntity.ok(Map.of("message", ""));
    }

    @GetMapping("/commands/{id}")
    public ResponseEntity<Map<String, String>> getCommand(Long id){
        return ResponseEntity.ok(Map.of("message", ""));
    }

    @PostMapping("/commands")
    public ResponseEntity<Map<String, String>> createCommand(Map<String, String> command){
        return ResponseEntity.ok(Map.of("message", ""));
    }

    @DeleteMapping("/commands/{id}")
    public ResponseEntity<Map<String, String>> deleteCommand(Long id){
        return ResponseEntity.ok(Map.of("message", ""));
    }
}
